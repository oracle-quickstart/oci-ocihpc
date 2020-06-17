// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

import (
	"crypto/md5"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/hex"
	"encoding/pem"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	homedir "github.com/mitchellh/go-homedir"
	"github.com/oracle/oci-go-sdk/common"
	"github.com/oracle/oci-go-sdk/example/helpers"
	"github.com/spf13/cobra"
)

var configureCmd = &cobra.Command{
	Use:   "configure",
	Short: "Configure ocihpc",
	Long: `
Example command: ocihpc configure
	`,
	Run: func(cmd *cobra.Command, args []string) {

		home, err := homedir.Dir()
		helpers.FatalIfError(err)

		configfile := filepath.Join(home, ".oci", "config")

		provider := common.DefaultConfigProvider()

		if _, err := os.Stat(configfile); err == nil {
			if ok, _ := common.IsConfigurationProviderValid(provider); ok {
				fmt.Printf("\nExisting configuration is valid. Please edit %s if you want to make changes to the configuration.\n\n", configfile)
			}
		} else {
			fmt.Printf("\nCould not find a valid configuration file. Please answer the following questions to create one:\n")
			createNewConfig(configfile)
		}

	},
}

func init() {
	rootCmd.AddCommand(configureCmd)

}

func createNewConfig(configfile string) {

	home, err := homedir.Dir()
	helpers.FatalIfError(err)

	var user string
	var tenancy string
	var region string
	var fingerprint string

	privateFileName := filepath.Join(home, ".oci", "ocihpc_key.pem")
	publicFileName := filepath.Join(home, ".oci", "ocihpc_key_public.pem")
	path := filepath.Join(home, ".oci")

	if _, err := os.Stat(path); os.IsNotExist(err) {
		os.MkdirAll(path, os.ModePerm)
	}

	file, err := os.OpenFile(configfile, os.O_RDWR|os.O_APPEND|os.O_CREATE, 0600)
	helpers.FatalIfError(err)

	defer file.Close()

	fmt.Printf("\nEnter your user OCID: ")
	fmt.Scanln(&user)

	fmt.Printf("\nEnter your tenancy OCID: ")
	fmt.Scanln(&tenancy)

	fmt.Printf("\nEnter your region: ")
	fmt.Scanln(&region)

	fingerprint = createKeys(privateFileName, publicFileName)

	content := fmt.Sprintf("[DEFAULT]\nuser=%s\nfingerprint=%s\nkey_file=%s\ntenancy=%s\nregion=%s", user, fingerprint, privateFileName, tenancy, region)
	_, err = file.WriteString(content)

	fmt.Printf("\nConfiguration file saved to: %s\n", configfile)
	fmt.Printf("\nIMPORTANT: Don't forget to upload your public key (%s).\n", publicFileName)
	fmt.Printf("\nYou can find the instructions for uploading the public key in this link: https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#three\n\n")

}

func createKeys(privateFileName string, publicFileName string) string {

	key, err := rsa.GenerateKey(rand.Reader, 2048)
	helpers.FatalIfError(err)

	publicKey := key.PublicKey

	// Create private key
	outFile, err := os.Create(privateFileName)
	helpers.FatalIfError(err)
	defer outFile.Close()

	var privateKey = &pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: x509.MarshalPKCS1PrivateKey(key),
	}

	err = pem.Encode(outFile, privateKey)
	err = os.Chmod(privateFileName, 0600)
	helpers.FatalIfError(err)

	// Create public key
	bytes, err := x509.MarshalPKIXPublicKey(&publicKey)
	helpers.FatalIfError(err)

	var pemkey = &pem.Block{
		Type:  "RSA PUBLIC KEY",
		Bytes: bytes,
	}

	pemfile, err := os.Create(publicFileName)
	helpers.FatalIfError(err)
	defer pemfile.Close()

	err = pem.Encode(pemfile, pemkey)
	helpers.FatalIfError(err)

	md5sum := md5.Sum(pemkey.Bytes)

	fp := make([]string, len(md5sum))
	for i, c := range md5sum {
		fp[i] = hex.EncodeToString([]byte{c})
	}

	fingerprint := strings.Join(fp, ":")

	return fingerprint

}
