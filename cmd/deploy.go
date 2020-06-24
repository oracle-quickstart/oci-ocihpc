// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

import (
	"bufio"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/oracle/oci-go-sdk/common"
	"github.com/oracle/oci-go-sdk/example/helpers"
	"github.com/oracle/oci-go-sdk/resourcemanager"
	"github.com/spf13/cobra"
)

type Stack struct {
	SourceStackName   string `json:"sourceStackName,omitempty"`
	DeployedStackName string `json:"deployedStackName,omitempty"`
	StackID           string `json:"stackID,omitempty"`
	StackIP           string `json:"stackIP,omitempty"`
	JobID             string `json:"jobID,omitempty"`
}

var s Stack

var deployCmd = &cobra.Command{
	Use:     "deploy",
	Aliases: []string{"create"},
	Short:   "Deploy a new stack",
	Long: `
Example command: ocihpc deploy --stack ClusterNetwork --node-count 2 --region us-ashburn-1 --compartment-id ocid1.compartment.oc1..nus3q
	`,

	Run: func(cmd *cobra.Command, args []string) {
		stack, _ := cmd.Flags().GetString("stack")
		s.SourceStackName = stack

		if _, err := os.Stat(".stackinfo.json"); err == nil {
			existingStackID := getStackID()
			if len(existingStackID) > 0 {
				isConfirmed := getConfirmation("\nThere is an existing stack in the current folder. If you deploy a new stack, you will have to delete related resources manually.\n\nDo you want to deploy a new stack and overwrite the existing one?")
				if !isConfirmed {
					os.Exit(1)
				}
			}
		}

		query := getStackQuery()
		addStackInfo(s)
		region, _ := cmd.Flags().GetString("region")
		compartmentID, _ := cmd.Flags().GetString("compartment-id")
		nodeCount, _ := cmd.Flags().GetString("node-count")

		if len(nodeCount) > 0 {
			if _, err := strconv.Atoi(nodeCount); err != nil {
				fmt.Printf("\nNode count must be a number, you entered: %s\n", nodeCount)
				os.Exit(1)
			}
		}

		provider := common.DefaultConfigProvider()
		client, err := resourcemanager.NewResourceManagerClientWithConfigurationProvider(provider)
		helpers.FatalIfError(err)

		ctx := context.Background()

		s.StackID = createStack(ctx, provider, client, compartmentID, region, stack, nodeCount)
		addStackInfo(s)

		s.JobID = createApplyJob(ctx, provider, client, s.StackID, region, stack)
		addStackInfo(s)

	},
}

func init() {
	rootCmd.AddCommand(deployCmd)

	deployCmd.Flags().StringP("compartment-id", "c", "", "Unique identifier (OCID) of the compartment that the stack will be deployed in.")
	deployCmd.MarkFlagRequired("compartment-id")

	deployCmd.Flags().StringP("region", "r", "", "The region to deploy to.")

	deployCmd.Flags().StringP("stack", "s", "", "Name of the stack you want to deploy.")
	deployCmd.MarkFlagRequired("stack")

	deployCmd.Flags().StringP("node-count", "n", query[s.SourceStackName].(map[string]interface{})["defaultNodeCount"], "Number of nodes to deploy.")
}

func createStack(ctx context.Context, provider common.ConfigurationProvider, client resourcemanager.ResourceManagerClient, compartment string, region string, stack string, nodeCount string) string {
	dir := filepath.Base(getWd())
	s.DeployedStackName = fmt.Sprintf("%s-%s-%s", stack, dir, getRandomNumber(4))
	addStackInfo(s)
	tenancyID, _ := provider.TenancyOCID()

	// Base64 the zip file.
	zipfile := stack + ".zip"
	zipFilePath := filepath.Join(getWd(), zipfile)

	f, _ := os.Open(zipFilePath)
	reader := bufio.NewReader(f)
	content, _ := ioutil.ReadAll(reader)
	encoded := base64.StdEncoding.EncodeToString(content)

	// Read config.json.
	file, err := os.Open("config.json")
	helpers.FatalIfError(err)

	defer file.Close()

	var config map[string]string
	if err := json.NewDecoder(file).Decode(&config); err != nil {
		log.Fatal(err)
	}

	config["tenancy_ocid"] = tenancyID
	config["compartment_ocid"] = compartment

	// Override region if entered.
	_, r := config["region"]
	if r {
		if len(region) > 0 {
			config["region"] = region
		}
	} else {
		config["region"] = region
	}

	// Override node count if entered.
	_, nc := config["node_count"]
	if nc {
		if len(nodeCount) > 0 {
			config["node_count"] = nodeCount
		}
	} else {
		fmt.Printf("\nChanging the node count is not supported with the stack %s, deploying stack with defaults.\n", stack)
	}

	req := resourcemanager.CreateStackRequest{
		CreateStackDetails: resourcemanager.CreateStackDetails{
			CompartmentId: common.String(compartment),
			ConfigSource: resourcemanager.CreateZipUploadConfigSourceDetails{
				ZipFileBase64Encoded: common.String(encoded),
			},
			DisplayName:      common.String(s.DeployedStackName),
			Description:      common.String(fmt.Sprintf("Deployed with ocihpc")),
			Variables:        config,
			TerraformVersion: common.String(query[stack].(map[string]interface{})["stackVersion"]),
		},
	}

	stackResp, err := client.CreateStack(ctx, req)
	helpers.FatalIfError(err)

	if err != nil {
		fmt.Println("Stack creation failed: ", err)
		os.Exit(1)
	}

	return *stackResp.Stack.Id

}

func createApplyJob(ctx context.Context, provider common.ConfigurationProvider, client resourcemanager.ResourceManagerClient, stackID string, region string, stack string) string {

	applyJobReq := resourcemanager.CreateJobRequest{
		CreateJobDetails: resourcemanager.CreateJobDetails{
			StackId:   common.String(stackID),
			Operation: "APPLY",
			JobOperationDetails: resourcemanager.CreateApplyJobOperationDetails{
				ExecutionPlanStrategy: "AUTO_APPROVED",
			},
		},
	}

	applyJobResp, err := client.CreateJob(ctx, applyJobReq)

	if err != nil {
		fmt.Println("Deployment failed with the following errors:\n\n", err)
		os.Exit(1)
	}

	jobLifecycle := resourcemanager.GetJobRequest{
		JobId: applyJobResp.Id,
	}

	fmt.Println()
	start := time.Now().Add(time.Second * -5)

	for {
		elapsed := int(time.Since(start).Seconds())
		readResp, err := client.GetJob(ctx, jobLifecycle)

		if err != nil {
			fmt.Println("Deployment failed with the following errors:\n\n", err)
			os.Exit(1)
		}

		fmt.Printf("Deploying stack: %s [%dmin %dsec]\n", s.DeployedStackName, elapsed/60, elapsed%60)
		time.Sleep(15 * time.Second)

		if readResp.LifecycleState == "SUCCEEDED" {
			fmt.Printf("\nDeployment of %s completed successfully\n", s.DeployedStackName)

			tfStateReq := resourcemanager.GetJobTfStateRequest{
				JobId: applyJobResp.Id,
			}
			tfStateResp, _ := client.GetJobTfState(ctx, tfStateReq)
			body, _ := ioutil.ReadAll(tfStateResp.Content)
			helpers.FatalIfError(err)
			s.StackIP = getOutputQuery(string(body), query[stack].(map[string]interface{})["outputQuery"])

			fmt.Printf("\nYou can connect to your bastion/headnode using the command: ssh %s@%s -i <location of the private key>\n\n", query[stack].(map[string]interface{})["stackUser"], s.StackIP)
			break
		} else if readResp.LifecycleState == "FAILED" {
			fmt.Printf("\nDeployment failed. Please note that there might be some resources that are already created. Run 'ocihpc delete --stack %s' to delete those resources.\n", stack)
			fmt.Printf("\nShowing error(s) below. If you want to get all the logs, you can run 'ocihpc get logs'.\n")
			getTFErrorLogs(ctx, provider, client, *applyJobResp.Id)
			break
		}
	}

	return *applyJobResp.Job.Id
}
