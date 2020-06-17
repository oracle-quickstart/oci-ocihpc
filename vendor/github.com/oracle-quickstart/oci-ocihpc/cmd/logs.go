// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"time"

	"github.com/oracle/oci-go-sdk/common"
	"github.com/oracle/oci-go-sdk/example/helpers"
	"github.com/oracle/oci-go-sdk/resourcemanager"
	"github.com/spf13/cobra"
)

var logsCmd = &cobra.Command{
	Use:   "logs",
	Short: "Get the logs of the last stack deployment",
	Long: `
Example command: ocihpc get logs
	`,

	Run: func(cmd *cobra.Command, args []string) {

		provider := common.DefaultConfigProvider()
		client, err := resourcemanager.NewResourceManagerClientWithConfigurationProvider(provider)
		helpers.FatalIfError(err)

		ctx := context.Background()

		if _, err := os.Stat(".stackinfo.json"); os.IsNotExist(err) || getJobID() == "" {
			fmt.Printf("\nError: Couldn't find a deployed stack here. Please check if this is the correct location.\n\n")
			os.Exit(1)
		}

		jobID := getJobID()
		logs, _ := getTFLogs(ctx, provider, client, jobID)
		fmt.Println(logs)
	},
}

func init() {
	getCmd.AddCommand(logsCmd)
}

func getTFLogs(ctx context.Context, provider common.ConfigurationProvider, client resourcemanager.ResourceManagerClient, jobID string) (string, error) {

	tf := resourcemanager.GetJobLogsRequest{
		JobId:     &jobID,
		SortOrder: "ASC",
	}

	resp, err := client.GetJobLogs(ctx, tf)
	helpers.FatalIfError(err)

	logs, err := json.MarshalIndent(resp.Items, "", "    ")
	helpers.FatalIfError(err)

	return string(logs), err

}

func getTFErrorLogs(ctx context.Context, provider common.ConfigurationProvider, client resourcemanager.ResourceManagerClient, jobID string) {

	tf := resourcemanager.GetJobLogsRequest{
		JobId:                         &jobID,
		TimestampGreaterThanOrEqualTo: &common.SDKTime{time.Now().Add(time.Second * -300)},
		SortOrder:                     "ASC",
	}

	resp, err := client.GetJobLogs(ctx, tf)
	helpers.FatalIfError(err)

	logs, err := json.MarshalIndent(resp.Items, "", "    ")
	helpers.FatalIfError(err)

	regex := regexp.MustCompile(`(?m)Error.*$`)
	matches := regex.FindAllString(string(logs), -1)
	for i, v := range matches {
		fmt.Printf("\nError %d: '%s'\n", i+1, v)
	}

}
