// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

import (
	"fmt"
	"runtime"

	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print ocihpc version information",
	Long: `
Example command: ocihpc version
	`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("ocihpc 1.0.0 %s/%s\n", runtime.GOOS, runtime.GOARCH)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
