#!/bin/bash

set -e

export OCIHPC_WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/" && pwd )"
export PACKAGE=$1
export PACKAGE="${PACKAGE%.*}"
export CURRENT_DIR=$(pwd)
export CURRENT_DIR_BASENAME=$(basename $CURRENT_DIR)
export ZIP_FILE_PATH="$CURRENT_DIR/$PACKAGE.zip"
export CONFIG_FILE_PATH="$CURRENT_DIR/config.json"
export NODE_AD=$(cat $CONFIG_FILE_PATH | jq -r .variables.ad)
export BASTION_NODE_AD=$(cat $CONFIG_FILE_PATH | jq -r .variables.bastion_ad)
export COMPARTMENT_ID=$(cat $CONFIG_FILE_PATH| jq -r .variables."compartment_ocid")
export REGION=$(cat $CONFIG_FILE_PATH | jq -r .variables.region)

RANDOM_NUMBER=$(( RANDOM % 10000 ))
DEPLOYMENT_NAME=${PACKAGE}-$CURRENT_DIR_BASENAME-$RANDOM_NUMBER
ORM_OUTPUT_QUERY=$(unzip -p $PACKAGE.zip ocihpc.json | jq -r .variables.orm_output_query)
NODE_SHAPE=$(unzip -p $PACKAGE.zip ocihpc.json | jq -r .variables.node_shape)
BASTION_NODE_SHAPE=$(unzip -p $PACKAGE.zip ocihpc.json | jq -r .variables.bastion_shape)

. "$OCIHPC_WORKDIR/../common/util.sh"

[ ! -f "$ZIP_FILE_PATH" ] && echo -e "\nPackage is not initialized. Please run ocihpc init <package name> to initialize.\n" && exit 1

check_prereqs
check_if_node_count_is_available $COUNT
check_if_authorized $NODE_SHAPE $NODE_AD
check_if_authorized $BASTION_NODE_SHAPE $BASTION_NODE_AD

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

rm -f $CURRENT_DIR/.info
rm -f $CURRENT_DIR/$DEPLOYMENT_NAME.access

CREATED_STACK_ID=$(oci resource-manager stack create --display-name "$DEPLOYMENT_NAME" --config-source $ZIP_FILE_PATH --from-json file://$CONFIG_FILE_PATH --compartment-id $COMPARTMENT_ID --region $REGION --terraform-version "0.12.x" --query 'data.id' --raw-output)
echo "STACK_ID=${CREATED_STACK_ID}" > $CURRENT_DIR/.info
echo "DEPLOYMENT_NAME=$DEPLOYMENT_NAME" >> $CURRENT_DIR/.info
CREATED_APPLY_JOB_ID=$(oci resource-manager job create-apply-job --stack-id $CREATED_STACK_ID --execution-plan-strategy AUTO_APPROVED --region $REGION --query 'data.id' --raw-output)

echo -e "\nStarting deployment...\n"

JOB_START_TIME=$SECONDS

while ! [[ $JOB_STATUS =~ ^(SUCCEEDED|FAILED) ]]
do
  ELAPSED_TIME=$(show_elapsed_time $JOB_START_TIME)
  echo -e "Deploying $DEPLOYMENT_NAME $ELAPSED_TIME"
  JOB_STATUS=$(oci resource-manager job get --job-id $CREATED_APPLY_JOB_ID --region $REGION --query 'data."lifecycle-state"' --raw-output)
  sleep 15
done

if [[ $JOB_STATUS == SUCCEEDED ]]
then
  STACK_IP=$(oci resource-manager job get-job-tf-state --file - --job-id $CREATED_APPLY_JOB_ID --region $REGION | jq -r $ORM_OUTPUT_QUERY)
  echo "STACK_IP=$STACK_IP" >> $CURRENT_DIR/.info
  echo -e "You can connect to your head node using the command:\nssh opc@$STACK_IP -i <location of the private key you used>" > $CURRENT_DIR/$DEPLOYMENT_NAME.access
  echo -e "\nSuccessfully deployed $DEPLOYMENT_NAME"
  echo -e "\nYou can connect to your head node using the command: ssh opc@$STACK_IP -i <location of the private key you used>"
  echo -e "\nYou can also find the IP address of the bastion/headnode in $CURRENT_DIR/$DEPLOYMENT_NAME.access file\n"
else
  TIME_RANGE=$(( $(date +%s) - 300 ))
  ERRORS_IN_TIME_RANGE=$(oci resource-manager job get-job-logs --job-id $CREATED_APPLY_JOB_ID --region $REGION --timestamp-greater-than-or-equal-to $TIME_RANGE --limit 250 --sort-order ASC | jq -r '.data[] | select(.message | contains("Error")) .message')
  echo -e "\nDeployment failed with the following error message:\n"
  echo -e "$ERRORS_IN_TIME_RANGE"
  echo -e "\nThe errors above may not include all the errors that caused the deployment to fail. For checking all logs in the console, please consult the following link:"
  echo -e "https://docs.cloud.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/managingstacksandjobs.htm#Downloads\n"
fi