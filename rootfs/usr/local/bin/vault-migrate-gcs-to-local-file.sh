#!/bin/bash

set -e                                     
set -o pipefail                                                                                                                                                               

[[ -z $TRACE ]] || set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/common.include
   
# checking pre-reqs

need "jq"
need "vault"

# ENV VARS

STORAGE_SOURCE_BUCKET=${STORAGE_SOURCE_BUCKET:-''}
STORAGE_DST_PATH=${STORAGE_DST_PATH:-''}
TMP_BACKUP_PATH="$STORAGE_DST_PATH/tmp/backup"

if [[ -z $STORAGE_SOURCE_BUCKET || -z $STORAGE_DST_PATH ]];then 
  die "Need to define STORAGE_SOURCE_BUCKET and STORAGE_DST_PATH"
fi

echo "Backup Started at `date`"
# Cleanup Destination
rm -rf "${TMP_BACKUP_PATH}/*"
# Create destination
mkdir -p "${TMP_BACKUP_PATH}"
mkdir -p "${STORAGE_DST_PATH}/data"

# Build Config file
jq -n --arg bucket "$STORAGE_SOURCE_BUCKET" --arg path "$TMP_BACKUP_PATH" '{"storage_source": {"gcs": {"bucket":$bucket}}, "storage_destination":{"file": {"path": $path}}}' > /tmp/migration.json

# Fetch Data
vault operator migrate -config /tmp/migration.json 2>&1  | egrep -v "\[INFO\]"

# Cleanup Backup
if [[ "x$VAULT_ROOT_UNSEAL_CLEANUP" == "xtrue" ]]; then
  echo "Cleaning up root and unseal keys files from backup as requested"
  rm -f $TMP_BACKUP_PATH/_vault-root
  rm -f $TMP_BACKUP_PATH/_vault-unseal*
fi

# Move data in final destination
mv "${STORAGE_DST_PATH}/data" "${STORAGE_DST_PATH}/data.old"
mv "${TMP_BACKUP_PATH}" "${STORAGE_DST_PATH}/data"
rm -rf "${STORAGE_DST_PATH}/data.old"

echo "Vault Data local backup Complete at `date`"
