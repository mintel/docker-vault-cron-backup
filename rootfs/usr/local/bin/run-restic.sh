#!/bin/bash
set -e 
set -o pipefail

[[ -z $TRACE ]] || set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/common.include

## Check Environment 
[[ -z $BACKUP_REPO ]] && die "BACKUP_REPO need to be set for restic-runner"
[[ -z $BACKUP_SET ]] && die "BACKUP_SET need to be set for restic-runner"

need 'restic'
need 'restic-runner'

## Initalize repository if is not already
bold "Initializing Repo if required"
restic-runner --repo $BACKUP_REPO command snapshots || restic-runner --repo $BACKUP_REPO init
echo ""

## Perform Restic Backup
bold "Performing Backup for $BACKUP_SET on $BACKUP_REPO"
restic-runner --repo $BACKUP_REPO --set $BACKUP_SET backup
echo ""

## Performing Expire of old snapshots
bold "Performing Expire for $BACKUP_REPO"
restic-runner --repo $BACKUP_REPO expire 
echo ""

## Performing a regular check of data integrity
## Since this is an expensive operatorion only run it in 10% of execution of this command
if [[ $((1 + RANDOM % 10)) -eq 10 ]]; then
  bold "Performing Check for $BACKUP_REPO"
  restic-runner --repo $BACKUP_REPO check
  echo ""
fi
