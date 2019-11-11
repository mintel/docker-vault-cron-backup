#!/bin/bash
set -e 
set -o pipefail

[[ -z $TRACE ]] || set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/common.include

## Check Environment 
#[[ -z $VAULT_GOOGLE_PROJECT_ID ]] && die "VAULT_GOOGLE_PROJECT_ID must be set"
[[ -z $VAULT_GOOGLE_APPLICATION_CREDENTIALS ]] && die "VAULT_GOOGLE_APPLICATION_CREDENTIALS must be set"
[[ -z $RESTIC_GOOGLE_PROJECT_ID ]] && die "RESTIC_GOOGLE_PROJECT_ID must be set"
[[ -z $RESTIC_GOOGLE_APPLICATION_CREDENTIALS ]] && die "RESTIC_GOOGLE_APPLICATION_CREDENTIALS must be set"
[[ -z $STORAGE_SOURCE_BUCKET ]] && die "STORAGE_SOURCE_BUCKET must be set"
[[ -z $STORAGE_DST_PATH ]] && die "STORAGE_DST_PATH must be set"
[[ -z $BACKUP_REPO ]] && die "BACKUP_REPO must be set"
[[ -z $BACKUP_SET ]] && die "BACKUP_SET must be set"

if [[ "x$VAULT_MIGRATE_RESET" == "xtrue" ]]; then
echo "#####################################"
echo "Performing Reset of backends"
GOOGLE_APPLICATION_CREDENTIALS=$VAULT_GOOGLE_APPLICATION_CREDENTIALS $DIR/vault-migrate-reset.sh
fi

echo "#####################################"
echo "Performing local backup of Vault Data"
GOOGLE_APPLICATION_CREDENTIALS=$VAULT_GOOGLE_APPLICATION_CREDENTIALS $DIR/vault-migrate-gcs-to-local-file.sh

echo ""
echo "#####################################"
echo "Backing up the local data with Restic"
GOOGLE_APPLICATION_CREDENTIALS=$RESTIC_GOOGLE_APPLICATION_CREDENTIALS GOOGLE_PROJECT_ID=$RESTIC_GOOGLE_PROJECT_ID $DIR/run-restic.sh
