// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/oracle/oci-go-sdk/common"
	"github.com/oracle/oci-go-sdk/example/helpers"
	"github.com/oracle/oci-go-sdk/resourcemanager"
	"github.com/spf13/cobra"
)

var deleteCmd = &cobra.Command{
	Use:     "delete",
	Aliases: []string{"del", "dlt"},
	Short:   "Delete a deployed stack",
	Long: `
Example command: ocihpc delete --stack ClusterNetwork`,

	Run: func(cmd *cobra.Command, args []string) {

		if _, err := os.Stat(".stackinfo.json"); os.IsNotExist(err) || getStackID() == "" {
			fmt.Printf("\nError: Couldn't find a deployed stack here. Please check if this is the correct location.\n\n")
			os.Exit(1)
		}

		provider := common.DefaultConfigProvider()
		stack, _ := cmd.Flags().GetString("stack")
		client, err := resourcemanager.NewResourceManagerClientWithConfigurationProvider(provider)
		helpers.FatalIfError(err)

		ctx := context.Background()

		stackID := getStackID()

		s.JobID = createDestroyJob(ctx, provider, client, stackID, stack)
	},
}

func init() {
	rootCmd.AddCommand(deleteCmd)

	deleteCmd.Flags().StringP("stack", "s", "", "Stack to delete")
	deleteCmd.MarkFlagRequired("stack")
}

func deleteStack(ctx context.Context, stackID string, client resourcemanager.ResourceManagerClient, stack string) {

	req := resourcemanager.DeleteStackRequest{
		StackId: common.String(stackID),
	}

	_, err := client.DeleteStack(ctx, req)
	helpers.FatalIfError(err)
}

func createDestroyJob(ctx context.Context, provider common.ConfigurationProvider, client resourcemanager.ResourceManagerClient, stackID string, stack string) string {

	destroyJobReq := resourcemanager.CreateJobRequest{
		CreateJobDetails: resourcemanager.CreateJobDetails{
			StackId:   common.String(stackID),
			Operation: "DESTROY",
			JobOperationDetails: resourcemanager.CreateDestroyJobOperationDetails{
				ExecutionPlanStrategy: "AUTO_APPROVED",
			},
		},
	}

	destroyJobResp, err := client.CreateJob(ctx, destroyJobReq)

	if err != nil {
		fmt.Println("\nDelete failed with the following errors:\n\n", err)
		os.Exit(1)
	}

	jobLifecycle := resourcemanager.GetJobRequest{
		JobId: destroyJobResp.Id,
	}

	fmt.Println()
	start := time.Now().Add(time.Second * -5)
	deployedStackName := getDeployedStackName()

	for {
		elapsed := int(time.Since(start).Seconds())
		readResp, err := client.GetJob(ctx, jobLifecycle)

		if err != nil {
			fmt.Println("\nDelete failed with the following errors:\n\n", err)
			os.Exit(1)
		}

		fmt.Printf("Deleting stack: %s [%dmin %dsec]\n", deployedStackName, elapsed/60, elapsed%60)
		time.Sleep(15 * time.Second)
		if readResp.LifecycleState == "SUCCEEDED" {
			deleteStack(ctx, stackID, client, stack)
			fmt.Printf("\nDelete completed successfully\n")
			os.Remove(".stackinfo.json")
			break
		} else if readResp.LifecycleState == "FAILED" {
			fmt.Printf("\nDeployment failed. You can run 'ocihpc get logs' to get the logs of the failed job\n")
			addStackInfo(s)
			break
		}
	}

	return *destroyJobResp.Job.Id
}
