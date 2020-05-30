#!/bin/bash

red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"

cli_log() {
  script_name=${0##*/}
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "== $script_name $timestamp $1"
}

export_config() {
   export OCI_USER_ID=$(awk -F'user=' '{print $2}' ~/.oci/config  | xargs)
   export OCI_TENANCY_ID=$(awk -F'tenancy=' '{print $2}' ~/.oci/config  | xargs)
   export OCI_REGION=$(awk -F'region=' '{print $2}' ~/.oci/config  | xargs)
}

newline() {
    echo -e "\n$1"
}

green() {
  echo -e "${green}${1}${end}"
}

yellow() {
  echo -e "${yellow}${1}${end}"
}

red() {
  echo -e "${red}${1}${end}"
}

check_prereqs () {
if ! [ -x "$(command -v oci)" ]; then
  echo 'Error: OCI CLI is not installed. Please follow the instructions in this link: https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm' >&2
  exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v unzip)" ]; then
  echo 'Error: unzip is not installed.' >&2
  exit 1
fi
}

is_node_count_available () {
  regex='^[0-9]+$|^$|^\s$'
  if ! [[ $1 =~ $regex ]] ; then
    echo "Error: Node count should be a number, you entered '$1'"; exit 1
  elif grep -q "node_count" config.json ; then
    change_count="$(jq --arg count $1 '.variables.node_count = $count' config.json)" && echo "${change_count}" > config.json
  else
    echo "Changing the node count is not supported with this package, deploying with defaults"
  fi
}

show_elapsed_time () {
  START_TIME=$1
  ELAPSED_TIME=$(($SECONDS - $START_TIME))
  echo "[$(($ELAPSED_TIME/60))min $(($ELAPSED_TIME%60))sec]"   
}