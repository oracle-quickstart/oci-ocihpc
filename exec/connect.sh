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
  connect    Connect to deployed solution
  *          Help
"
  exit 1
}

STACK_IP=$(awk -F'STACK_IP=' '{print $2}' $OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/.info | xargs)

echo -e "\nConnecting to opc@$STACK_IP"
ssh opc@$STACK_IP

