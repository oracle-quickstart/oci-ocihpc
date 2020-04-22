#!/bin/bash

set -e

export OCIHPC_WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
export PACKAGE=$1

source "$OCIHPC_WORKDIR/common/util.sh"

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


STACK_ID=$(awk -F'STACK_ID=' '{print $2}' $OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/.info | xargs)

echo -e "\nCreating Destroy Job"
CREATED_DESTROY_JOB_ID=$(oci resource-manager job create-destroy-job --stack-id $STACK_ID --execution-plan-strategy=AUTO_APPROVED --query 'data.id' --raw-output)
echo -e "\nCreated Destroy Job Id: ${CREATED_DESTROY_JOB_ID}"
echo -e "\nWaiting for job to complete...\n"

while ! [[ $JOB_STATUS =~ ^(SUCCEEDED|FAILED) ]]
do
  sleep 5
  JOB_STATUS=$(oci resource-manager job get --job-id ${CREATED_DESTROY_JOB_ID} --query 'data."lifecycle-state"' --raw-output)
done

echo "Delete job has $JOB_STATUS"
echo -e "\nDeleting Stack"
oci resource-manager stack delete --stack-id $STACK_ID --force
echo "\nSuccesfuly deleted Stack Id: $STACK_ID"