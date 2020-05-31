#!/bin/bash

set -e

export OCIHPC_WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
. "$OCIHPC_WORKDIR/../common/util.sh"

usage() {
  cli_name=${0##*/}
  echo "
Oracle Cloud Infrastructure Easy HPC Deploy

Usage: $cli_name [command]

Commands:
  list    Lists available packages for deployment
  *         Help
"
  exit 1
}

echo -e "\nList of available packages:\n"
echo -e "$(curl -s https://raw.githubusercontent.com/oracle-quickstart/oci-ocihpc/master/packages/catalog)\n"