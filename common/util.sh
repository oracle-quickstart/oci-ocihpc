#!/bin/bash

red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"

zip_edit(){
    echo "Usage: zipedit archive.zip file.txt"
    unzip "$1" "$2" -d /tmp 
    vi /tmp/$2 && zip -j --update "$1"  "/tmp/$2" 
}

parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

cli_log() {
  script_name=${0##*/}
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "== $script_name $timestamp $1"
}

export_config() {
   export OCI_USER_ID=$(awk -F'user=' '{print $2}' ~/.oci/config  | xargs)
   export OCI_TENANCY_ID=$(awk -F'tenancy=' '{print $2}' ~/.oci/config  | xargs)
   export OCI_REGION=$(awk -F'region=' '{print $2}' ~/.oci/config  | xargs)
}

newline() {
    echo -e "\n$1"
}

green() {
  echo -e "${green}${1}${end}"
}

yellow() {
  echo -e "${yellow}${1}${end}"
}

red() {
  echo -e "${red}${1}${end}"
}


showLoading() {
  mypid=$!
  loadingText=$1

  echo -ne "$loadingText\r"

  while kill -0 $mypid 2>/dev/null; do
    echo -ne "$loadingText.\r"
    sleep 0.5
    echo -ne "$loadingText..\r"
    sleep 0.5
    echo -ne "$loadingText...\r"
    sleep 0.5
    echo -ne "\r\033[K"
    echo -ne "$loadingText\r"
    sleep 0.5
  done

  echo "$loadingText...COMPLETED"
}