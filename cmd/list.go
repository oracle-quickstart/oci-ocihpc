// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

import (
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/oracle/oci-go-sdk/example/helpers"
	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List available stacks",
	Long: `
Example command: ocihpc list
	`,

	Run: func(cmd *cobra.Command, args []string) {
		url := "https://raw.githubusercontent.com/oracle-quickstart/oci-ocihpc/master/stacks/catalog"
		resp, err := http.Get(url)
		helpers.FatalIfError(err)
		defer resp.Body.Close()

		respData, err := ioutil.ReadAll(resp.Body)
		helpers.FatalIfError(err)

		respString := string(respData)

		fmt.Printf("\nList of available stacks:\n\n")
		fmt.Println(respString)
		fmt.Println()
	},
}

func init() {
	rootCmd.AddCommand(listCmd)
}
