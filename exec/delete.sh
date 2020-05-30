#!/bin/bash

set -e

export OCIHPC_WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
export PACKAGE=$1
export PACKAGE="${PACKAGE%.*}"

. "$OCIHPC_WORKDIR/common/util.sh"

CURRENT_DIR=$(pwd)
CURRENT_DIR_BASENAME=$(basename $CURRENT_DIR)
ZIP_FILE_PATH="$CURRENT_DIR/$PACKAGE.zip"
CONFIG_FILE_PATH="$CURRENT_DIR/config.json"
COMPARTMENT_ID=$(cat $CONFIG_FILE_PATH| jq -r .variables."compartment_ocid")
REGION=$(cat $CONFIG_FILE_PATH | jq -r .variables.region)

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
DEPLOYMENT_NAME=$(awk -F'DEPLOYMENT_NAME=' '{print $2}' $CURRENT_DIR/.info | xargs)

CREATED_DESTROY_JOB_ID=$(oci resource-manager job create-destroy-job --stack-id $STACK_ID --execution-plan-strategy=AUTO_APPROVED --region $REGION --query 'data.id' --raw-output)

echo -e "\n"

rm -f $CURRENT_DIR/$DEPLOYMENT_NAME.access

JOB_START_TIME=$SECONDS

while ! [[ $JOB_STATUS =~ ^(SUCCEEDED|FAILED) ]]
do
  ELAPSED_TIME=$(show_elapsed_time $JOB_START_TIME)
  echo "Deleting $DEPLOYMENT_NAME $ELAPSED_TIME"
  JOB_STATUS=$(oci resource-manager job get --job-id ${CREATED_DESTROY_JOB_ID} --region $REGION --query 'data."lifecycle-state"' --raw-output)
  sleep 15
done

oci resource-manager stack delete --stack-id $STACK_ID --region $REGION --force

if [[ $JOB_STATUS == SUCCEEDED ]]
then
  echo -e "\nSuccesfuly deleted $DEPLOYMENT_NAME\n"
else
  echo -e "Delete failed. Please check logs in the console. More info: https://docs.cloud.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/managingstacksandjobs.htm#Downloads"
fi