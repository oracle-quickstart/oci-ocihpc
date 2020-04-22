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
  init    Initializes the package for deployment
  *         Help
"
  exit 1
}

ZIP_FILE_PATH="$OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/$PACKAGE.zip"
CONFIG_FILE_PATH="$OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/config.json"
ZIP_FILE_URL="https://github.com/OguzPastirmaci/ocihpc/raw/master/packages/$PACKAGE/$PACKAGE.zip"
CONFIG_FILE_URL="https://raw.githubusercontent.com/OguzPastirmaci/ocihpc/master/packages/$PACKAGE/config.json"

if curl --head --silent --fail $ZIP_FILE_URL > /dev/null;
 then
  echo -e "\nDownlading package: $PACKAGE"
  [ ! -d "$OCIHPC_WORKDIR/downloaded-packages/$PACKAGE" ] && mkdir -p "$OCIHPC_WORKDIR/downloaded-packages/$PACKAGE"
  [ ! -f "$ZIP_FILE_PATH" ] && curl -sL $ZIP_FILE_URL -o $ZIP_FILE_PATH > /dev/null
  [ ! -f "$CONFIG_FILE_PATH" ] && curl -s $CONFIG_FILE_URL -o $CONFIG_FILE_PATH  > /dev/null
  echo -e "\nPackage $PACKAGE downloaded to $OCIHPC_WORKDIR/downloaded-packages/$PACKAGE"
  echo -e "\nIMPORTANT: Edit the contents of the $OCIHPC_WORKDIR/downloaded-packages/$PACKAGE/config.json file before running ocihpc deploy command\n"
 else
  echo -e "\nThe package $PACKAGE does not exist.\n"
  $OCIHPC_WORKDIR/ocihpc.sh list
  exit
fi