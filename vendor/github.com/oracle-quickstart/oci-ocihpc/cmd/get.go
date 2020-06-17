// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var getCmd = &cobra.Command{
	Use:   "get",
	Short: "Get information about a deployed stack",
	Long: `
Example command: ocihpc get logs
	`,
	RunE: requireSubcommand,

	Run: func(cmd *cobra.Command, args []string) {

	},
}

func init() {
	rootCmd.AddCommand(getCmd)
}

func requireSubcommand(cmd *cobra.Command, args []string) error {
	return fmt.Errorf("ocihpc %s requires a subcommand after it.", cmd.Name())
}
