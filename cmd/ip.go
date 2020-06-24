// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var ipCmd = &cobra.Command{
	Use:   "ip",
	Short: "Get the IP address of the headnode or the bastion of a stack",
	Long: `
Example command: ocihpc get ip
	`,

	Run: func(cmd *cobra.Command, args []string) {

		if _, err := os.Stat(".stackinfo.json"); err == nil {
			if getStackIP() != "" {
				stackName := getSourceStackName()
				fmt.Printf("\nYou can connect to your bastion/headnode using the following command:\n\n")
				fmt.Printf("ssh %s@%s -i <location of the private key>\n\n", getStackQuery(stackName, "stackUser"), getStackIP())
			} else if getStackIP() == "" {
				fmt.Printf("\nError: Couldn't find a deployed stack here. Please check if this is the correct location.\n\n")
			}
		} else {
			fmt.Printf("\nError: Couldn't find a deployed stack here. Please check if this is the correct location.\n\n")
		}

	},
}

func init() {
	getCmd.AddCommand(ipCmd)
}
