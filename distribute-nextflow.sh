#!/bin/bash -e

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# SUMMARY
#
#   TODO
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# USAGE
#   TODO
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


## Script parameters

PARAM_NF_SOURCE="$1"
PARAM_NF_TARGET_DIR="$2"
PARAM_SETUP_SCRIPT="$3"
PARAM_USER="$4"
PARAM_IGNITE_MODE="$5"          # "daemon" == true
PARAM_IGNITE_DISCOVERY_DIR="$6" 
PARAM_PURGE_FLAG="$7"           # "purge" == true


## Constants

DAEMON_MODE="daemon"
PURGE_FLAG="purge"


## Checking parameters

if [ "$#" -ne 7 ]; then
  echo "[-] invalid number of parameters"
  exit 1
fi

echo "[+] using nextflow source: $PARAM_NF_SOURCE"
echo "[+] will install nextflow on remote hosts at: $PARAM_NF_TARGET_DIR"
echo "[+] using setup script: $PARAM_SETUP_SCRIPT"
echo "[+] using ssh user: $PARAM_USER"

if [ "$PARAM_IGNITE_MODE" == "$DAEMON_MODE" ]; then
  echo "[+] received flag to start ignite daemon on remote hosts"
else
  echo "[+] wont start nextflow daemon on remote hosts"
fi

echo "[+] using ignite discovery dir: $PARAM_IGNITE_DISCOVERY_DIR"


if [ "$PARAM_PURGE_FLAG" == "$PURGE_FLAG" ]; then
  echo "[~] purge flag received, will delete existing nextflow installation on remote hosts"
else
  echo "[+] no purge received, wont touch existing nextflow"
fi


## Find remote hosts

# get the hostname of each slurm cluster nodes
HOST_NAMES=($(sinfo | grep bibigrid | tr -s " "  | cut -d " " -f 6 | tr "," "\n"))

EXEC_HOST="$(hostname)"

echo "[+] [$EXEC_HOST] start distributing nextflow to ${#HOST_NAMES[@]} remote hosts: ${HOST_NAMES[*]}"


## Conditionally cleanup ignite discovery directory 

if [ "$PARAM_IGNITE_MODE" == "$DAEMON_MODE" ]; then
  echo "[+] [$EXEC_HOST] cleaning up nf ignite discovery dir at: $PARAM_IGNITE_DISCOVERY_DIR"
  rm -rf "${PARAM_IGNITE_DISCOVERY_DIR:?}/*"
fi


## Run setup on remote hosts

for host in "${HOST_NAMES[@]}"
do
  SSH_HOST="$PARAM_USER@$host"
  
  echo "[+] [$EXEC_HOST] distributing nextflow to host: $host"


  ## Conditionally purge and copy current nextflow source files

  if ssh "$SSH_HOST" '[ -d '"$PARAM_NF_TARGET_DIR"' ]' && [ "$PARAM_PURGE_FLAG" != "$PURGE_FLAG" ]; then
    echo "[+] [$EXEC_HOST] nextflow directory already exists on host and force override is not defined"
  else
    echo "[+] [$EXEC_HOST] nextflow not present or purge defined"

    echo "[+] [$EXEC_HOST] deleting previous nextflow files at: $SSH_HOST:$PARAM_NF_TARGET_DIR"
    ssh "$SSH_HOST" 'rm -rfv '"$PARAM_NF_TARGET_DIR" > /dev/null

    echo "[+] [$EXEC_HOST] copying nextflow to: $SSH_HOST:$PARAM_NF_TARGET_DIR"
    scp -r "$PARAM_NF_SOURCE" "$SSH_HOST":"$PARAM_NF_TARGET_DIR" > /dev/null
  fi

  echo "[+] [$EXEC_HOST] copy setup script to remote host: $host"
  scp "$PARAM_SETUP_SCRIPT" "$SSH_HOST":~/setup-nextflow.sh

  cmd='chmod +x ~/setup-nextflow.sh; ~/setup-nextflow.sh '"$PARAM_NF_TARGET_DIR/nextflow $PARAM_IGNITE_MODE $PARAM_IGNITE_DISCOVERY_DIR"'; exit;'

  echo "[+] [$EXEC_HOST] start setup on: $host"
  ssh -t "$SSH_HOST" "$cmd"
done

echo "[+] [$EXEC_HOST] done distributing nextflow \\o/"



  # echo "[+] [$EXEC_HOST] begin executing nextflow setup on host: $host"
  # PARAMLIST=("$PARAM_NF_TARGET_DIR/nextflow" "$PARAM_IGNITE_DISCOVERY_DIR" "$PARAM_IGNITE_MODE")
  # printf -v params '%q ' "${PARAMLIST[@]}"
  # ssh  "$SSH_HOST" "bash -s -- $params" < "$PARAM_SETUP_SCRIPT" # $PARAM_NF_TARGET_DIR/nextflow $PARAM_IGNITE_DISCOVERY_DIR $PARAM_IGNITE_MODE