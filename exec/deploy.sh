#!/bin/bash

set -e

export OCIHPC_WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
export PACKAGE=$1

ZIP_FILE_PATH="$OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/$PACKAGE.zip"
CONFIG_FILE_PATH="$OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/config.json"

source "$OCIHPC_WORKDIR/common/util.sh"

usage() {
  cli_name=${0##*/}
  echo "
Oracle Cloud Infrastructure Easy HPC Deploy

Usage: $cli_name [command]

Commands:
  deploy    Create a deployment
"
  exit 1 
}

[ ! -d "$OCIHPC_WORKDIR/downloaded-packages/$PACKAGE" ] && echo -e "\nPackage is not initialized. Please run 'ocihpc init $PACKAGE'.\n" && exit 1

echo -e "\nCreating stack: $PACKAGE"
CREATED_STACK_ID=$(oci resource-manager stack create --display-name "${PACKAGE}-EasyDeploy" --config-source $ZIP_FILE_PATH --working-directory / --from-json file://$CONFIG_FILE_PATH --query 'data.id' --raw-output)
echo -e "\nCreated stack id: ${CREATED_STACK_ID}"
echo "STACK_ID=${CREATED_STACK_ID}" > $OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/.info
echo -e "\nDeploying $PACKAGE"
CREATED_PLAN_JOB_ID=$(oci resource-manager job create-apply-job --stack-id $CREATED_STACK_ID --execution-plan-strategy AUTO_APPROVED --query 'data.id' --raw-output)
echo -e "\nCreated Apply Job id: ${CREATED_PLAN_JOB_ID}"
echo -e "\nWaiting for job to complete..."

while ! [[ $JOB_STATUS =~ ^(SUCCEEDED|FAILED) ]]
do
  JOB_STATUS=$(oci resource-manager job get --job-id ${CREATED_PLAN_JOB_ID} --query 'data."lifecycle-state"' --raw-output)
done


if [[ $JOB_STATUS == SUCCEEDED ]]
then
  STACK_IP=$(oci resource-manager job get-job-tf-state --file - --job-id $CREATED_PLAN_JOB_ID | awk -F\" '/ip_addresses.0/{print $4; exit}') >> $OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/.info
  echo "STACK_IP=$STACK_IP" >> $OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/.info
  echo -e "\nJob has $JOB_STATUS"
  echo -e "\nYou can connect to your OpenFOAM instance using the IP: $STACK_IP\n"
else
  echo -e "Deployment failed. Please check logs."
fi


