#!/bin/bash

###############################################################################
#
# Takes a comma separated list of hosts ($1) and executes a local script ($2) 
# on each of those host
#
###############################################################################


PARAM_HOSTS="$1"
PARAM_SCRIPT="$2"

if [ "$PARAM_HOSTS" == "" ]; then
  echo "[-] host list is missing"
  exit 1
fi

if [ "$PARAM_SCRIPT" == "" ]; then
  echo "[-] target script is missing"
  exit 1
fi

IFS=',' read -ra REMOTE_HOSTS <<< $PARAM_HOSTS

echo "[+] will run $PARAM_SCRIPT on ${#REMOTE_HOSTS[@]}"

for host in "${REMOTE_HOSTS[@]}"
do

  SSH_HOST="ubuntu@$host"
  echo "[+] executing $PARAM_SCRIPT on $SSH_HOST"
  ssh "$SSH_HOST" 'bash -s' < $PARAM_SCRIPT

  if [[ $? -ne 0 ]]; then
    echo "[-] ERROR: $host did not complete successfully"
  else
    echo "[+] $host complete"
  fi

done
