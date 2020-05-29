#!/bin/bash

set -e

export OCIHPC_WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
export PACKAGE=$1

source "$OCIHPC_WORKDIR/common/util.sh"

CURRENT_DIR=$(pwd)
CURRENT_DIR_BASENAME=$(basename $CURRENT_DIR)
ZIP_FILE_PATH="$CURRENT_DIR/$PACKAGE.zip"
CONFIG_FILE_PATH="$CURRENT_DIR/config.json"
COMPARTMENT_ID=$(cat $CONFIG_FILE_PATH| jq -r .variables."compartment_ocid")
REGION=$(cat $CONFIG_FILE_PATH | jq -r .variables.region)
RANDOM_NUMBER=$(( RANDOM % 10000 ))
DEPLOYMENT_NAME=${PACKAGE}-$CURRENT_DIR_BASENAME-$RANDOM_NUMBER


usage() {
  cli_name=${0##*/}
  echo "
Oracle Cloud Infrastructure Easy HPC Deploy

Usage: $cli_name [command]

Commands:
  delete    Delete a deployment
"
  exit 1
}


STACK_ID=$(awk -F'STACK_ID=' '{print $2}' $CURRENT_DIR/.info | xargs)

echo -e "\nCreating Destroy Job"
CREATED_DESTROY_JOB_ID=$(oci resource-manager job create-destroy-job --stack-id $STACK_ID --execution-plan-strategy=AUTO_APPROVED --region $REGION --query 'data.id' --raw-output)
echo -e "\nCreated Destroy Job Id: ${CREATED_DESTROY_JOB_ID}"

while ! [[ $JOB_STATUS =~ ^(SUCCEEDED|FAILED) ]]
do
  echo -e "\nDeleting $DEPLOYMENT_NAME"
  JOB_STATUS=$(oci resource-manager job get --job-id ${CREATED_DESTROY_JOB_ID} --region $REGION --query 'data."lifecycle-state"' --raw-output)
  sleep 15
done

echo "Delete job has $JOB_STATUS"
echo -e "\nDeleting Stack"
oci resource-manager stack delete --stack-id $STACK_ID --region $REGION --force
echo -e "\nSuccesfuly deleted Stack Id: $STACK_ID\n"