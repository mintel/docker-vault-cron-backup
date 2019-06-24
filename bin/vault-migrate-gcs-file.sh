#!/bin/bash


set -e                                     
set -o pipefail                                                                                                                                                               


[[ -z $TRACE ]] || set -x
   
die() { echo "$*" 1>&2 ; exit 1; }

need() {
  command -v "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need_dir() {
  [[ -d "$1" ]] || die "Directory '$1' is missing but required"
}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd > /dev/null
}

# checking pre-reqs

need "jq"
need "vault"

# ENV VARS

STORAGE_SOURCE=${STORAGE_SOURCE:-''}
STORAGE_DST=${STORAGE_DST:-''}

MIGRATION_CONFIG_FILE=${MIGRATION_CONFIG_FILE:-''}

if [[ -z $MIGRATION_CONFIG_FILE ]];then 
  die "Need a migration configuration file for vault"
fi

cat $MIGRATION_CONFIG_FILE | jq . 2>/dev/null >/dev/null
if [[ $? -ne 0 ]]; then
  die "$MIGRATION_CONFIG_FILE is not a valid JSON file. We only support json config format"
fi

DESTINATION_PATH="$(cat $MIGRATION_CONFIG_FILE | jq -r .storage_destination.file.path)"
if [[ -z $DESTINATION_PATH ]]; then
  die "Could not extract destination path from $MIGRATION_CONFIG_FILE"
fi

# Cleanup Destination
rm -rf $DESTINATION_PATH/*

# Create TMP destination
mkdir -p "/tmp/backup"

cat $MIGRATION_CONFIG_FILE | jq '.storage_destination.file.path = "/tmp/backup"' > /tmp/migration.json

# Fetch Data
vault operator migrate -config /tmp/migration.json

# Cleanup Backup
rm -f /tmp/backup/_vault-root
rm -f /tmp/backup/_vault-unseal*

# Move data in final destination
mv /tmp/backup/* $DESTINATION_PATH
rm -rf /tmp/backup
