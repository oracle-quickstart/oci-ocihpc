// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strings"

	"github.com/oracle/oci-go-sdk/example/helpers"
)

var filename = ".stackinfo.json"

func addStackInfo(s Stack) {

	file, _ := json.MarshalIndent(s, "", " ")
	_ = ioutil.WriteFile(filename, file, 0644)
}

func getSourceStackName() string {

	content, err := ioutil.ReadFile(filename)
	helpers.FatalIfError(err)

	var info Stack
	json.Unmarshal([]byte(content), &info)

	return info.SourceStackName
}

func getDeployedStackName() string {

	content, err := ioutil.ReadFile(filename)
	helpers.FatalIfError(err)

	var info Stack
	json.Unmarshal([]byte(content), &info)

	return info.DeployedStackName
}

func getStackID() string {

	content, err := ioutil.ReadFile(filename)
	helpers.FatalIfError(err)

	var info Stack
	json.Unmarshal([]byte(content), &info)

	return info.StackID
}

func getStackIP() string {

	content, err := ioutil.ReadFile(filename)
	helpers.FatalIfError(err)

	var info Stack
	json.Unmarshal([]byte(content), &info)

	return info.StackIP
}

func getJobID() string {

	content, err := ioutil.ReadFile(filename)
	helpers.FatalIfError(err)

	var info Stack
	json.Unmarshal([]byte(content), &info)

	return info.JobID
}

func getWd() string {
	dir, err := os.Getwd()
	helpers.FatalIfError(err)

	return dir
}

func downloadFile(filepath string, url string) error {

	resp, err := http.Get(url)
	helpers.FatalIfError(err)

	defer resp.Body.Close()

	out, err := os.Create(filepath)
	helpers.FatalIfError(err)

	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return err
}

func getRandomNumber(n int) string {
	numbers := []rune("0123456789")

	b := make([]rune, n)
	for i := range b {
		b[i] = numbers[rand.Intn(len(numbers))]
	}
	return string(b)
}

func getOutputQuery(data string, query string) string {

	var p map[string]interface{}
	json.Unmarshal([]byte(data), &p)
	q := p["outputs"].(map[string]interface{})[query].(map[string]interface{})["value"]
	str := fmt.Sprint(q)
	return str
}

func getConfirmation(prompt string) bool {
	var response string

	fmt.Printf("\n%s (y/n): ", prompt)
	_, err := fmt.Scanln(&response)
	if err != nil {
		log.Fatal(err)
	}

	switch strings.ToLower(response) {
	case "y", "yes":
		return true
	case "n", "no":
		return false
	default:
		fmt.Println(prompt)
		return getConfirmation(prompt)
	}
}

func getStackQuery(stack string, value string) string {
	url := "https://raw.githubusercontent.com/oracle-quickstart/oci-ocihpc/master/stacks/stackQuery.json"
	resp, err := http.Get(url)
	if err != nil {
		log.Fatal(err)
	}
	var query map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&query)
	if err != nil {
		log.Fatal(err)
	}
	return query[stack].(map[string]interface{})[value]
}
