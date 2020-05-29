#!/bin/bash

set -e

export OCIHPC_WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )"
export PACKAGE=$1

CURRENT_DIR=$(pwd)
CURRENT_DIR_BASENAME=$(basename $CURRENT_DIR)
ZIP_FILE_PATH="$CURRENT_DIR/$PACKAGE.zip"
CONFIG_FILE_PATH="$CURRENT_DIR/config.json"
COMPARTMENT_ID=$(cat $CONFIG_FILE_PATH| jq -r .variables."compartment_ocid")
REGION=$(cat $CONFIG_FILE_PATH | jq -r .variables.region)
RANDOM_NUMBER=$(( RANDOM % 10000 ))
DEPLOYMENT_NAME=${PACKAGE}-$CURRENT_DIR_BASENAME-$RANDOM_NUMBER
#CONNECTION_IP=$(unzip -p $PACKAGE.zip ocihpc-connection)

#source "$OCIHPC_WORKDIR/common/util.sh"

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

[ ! -f "$ZIP_FILE_PATH" ] && echo -e "\nPackage is not initialized. Please run 'ocihpc init $PACKAGE'.\n" && exit 1

echo -e "\nCreating stack: $DEPLOYMENT_NAME"
CREATED_STACK_ID=$(oci resource-manager stack create --display-name "$DEPLOYMENT_NAME" --config-source $ZIP_FILE_PATH --from-json file://$CONFIG_FILE_PATH --compartment-id $COMPARTMENT_ID --region $REGION --terraform-version "0.12.x" --query 'data.id' --raw-output)
echo -e "\nCreated stack id: ${CREATED_STACK_ID}"
echo "STACK_ID=${CREATED_STACK_ID}" > $CURRENT_DIR/.info
echo -e "\nDeploying $DEPLOYMENT_NAME"
CREATED_APPLY_JOB_ID=$(oci resource-manager job create-apply-job --stack-id $CREATED_STACK_ID --execution-plan-strategy AUTO_APPROVED --region $REGION --query 'data.id' --raw-output)
echo -e "\nCreated Apply Job id: ${CREATED_APPLY_JOB_ID}"

while ! [[ $JOB_STATUS =~ ^(SUCCEEDED|FAILED) ]]
do
  echo -e "\nDeploying $DEPLOYMENT_NAME"
  JOB_STATUS=$(oci resource-manager job get --job-id ${CREATED_APPLY_JOB_ID} --region $REGION --query 'data."lifecycle-state"' --raw-output)
  sleep 15
done

if [[ $JOB_STATUS == SUCCEEDED ]]
then
  STACK_IP=$(oci resource-manager job get-job-tf-state --file - --job-id $CREATED_APPLY_JOB_ID --region $REGION | jq -r '$CONNECTION_IP"' | grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)') >> $CURRENT_DIR/.info
  echo "STACK_IP=$STACK_IP" >> $CURRENT_DIR/.info
  echo -e "\nSuccessfully deployed $DEPLOYMENT_NAME"
  echo -e "\nYou can connect to your head node using the IP: $STACK_IP\n"
  echo -e "ocihpc connect $STACK_IP -i <location of the private key you used>\n"
else
  echo -e "Deployment failed. Please check logs."
fi