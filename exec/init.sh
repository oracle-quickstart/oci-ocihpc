#!/bin/bash

set -e

export OCIHPC_WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PACKAGE=$1

#. "$OCIHPC_WORKDIR/common/util.sh"

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

CURRENT_DIR=$OCIHPC_WORKDIR
CURRENT_DIR_BASENAME=$(basename $CURRENT_DIR)
ZIP_FILE_PATH="$CURRENT_DIR/$PACKAGE.zip"
CONFIG_FILE_PATH="$CURRENT_DIR/config.json"
ZIP_FILE_URL="https://github.com/OguzPastirmaci/ocihpc/raw/update-1/packages/$PACKAGE/$PACKAGE.zip"
CONFIG_FILE_URL="https://raw.githubusercontent.com/OguzPastirmaci/ocihpc/update-1/packages/$PACKAGE/config.json"


if curl --head --silent --fail $ZIP_FILE_URL > /dev/null;
 then
  echo -e "\nDownlading package: $PACKAGE"
  curl -sL $ZIP_FILE_URL -o $ZIP_FILE_PATH > /dev/null
  [ ! -f "$CONFIG_FILE_PATH" ] && curl -s $CONFIG_FILE_URL -o $CONFIG_FILE_PATH  > /dev/null
  echo -e "\nPackage $PACKAGE downloaded to $CURRENT_DIR/"
  echo -e "\nIMPORTANT: Edit the contents of the $CURRENT_DIR/config.json file before running ocihpc deploy command\n"
 else
  echo -e "\nThe package $PACKAGE does not exist.\n"
  ocihpc list
  exit
fi