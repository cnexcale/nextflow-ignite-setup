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
PARAM_PURGE_FLAG="$5"           # "purge" == true
PARAM_IGNITE_MODE="$6"          # "daemon" == true
PARAM_IGNITE_DISCOVERY="$7"     # directory or <ip>[,<ip>,...]

## Constants

DAEMON_MODE="daemon"
PURGE_FLAG="purge"


## Checking parameters

if [ "$#" -ne 7 ]; then
  echo "[-] invalid number of parameters"
  exit 1
fi

if ! [[ $PARAM_NF_TARGET_DIR =~ ^/ ]]; then
  echo "[-] nextflow target dir is not an absolute path: $PARAM_NF_TARGET_DIR"
  exit 1
fi

if [ "$PARAM_IGNITE_MODE" == "$DAEMON_MODE" ]; then
  echo "[+] received flag to start ignite daemon on remote hosts"
else
  echo "[+] wont start nextflow daemon on remote hosts"
fi


if [ "$PARAM_PURGE_FLAG" == "$PURGE_FLAG" ]; then
  if [[ $PARAM_NF_TARGET_DIR =~ ^/$ ]]; then
    # refuse to purge root dir
    echo "[-] target nextflow dir is not valid with purge flag defined: $PARAM_NF_TARGET_DIR"
    exit 1
  fi
  echo "[~] purge flag received, will delete existing nextflow installation on remote hosts"
else
  echo "[+] no purge received, wont touch existing nextflow"
fi

echo "[+] using nextflow source: $PARAM_NF_SOURCE"
echo "[+] will install nextflow on remote hosts at: $PARAM_NF_TARGET_DIR"
echo "[+] using setup script: $PARAM_SETUP_SCRIPT"
echo "[+] using ssh user: $PARAM_USER"
echo "[+] using ignite discovery: $PARAM_IGNITE_DISCOVERY"


## Find remote hosts

EXEC_HOST="$(hostname)"
REMOTE_HOSTS=()
IGNITE_DISCOVERY_MODE=""

IP_REGEX="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]{1,5})?"
if [[ $PARAM_IGNITE_DISCOVERY =~ $IP_REGEX ]]; then

  echo "[+] [$EXEC_HOST] using IP addresses for remote host resolution and node discovery"

  # get the remote host of the list of specified IPs
  IFS=',' read -ra REMOTE_HOSTS <<< $PARAM_IGNITE_DISCOVERY
  IGNITE_DISCOVERY_MODE="ip"
else

  echo "[+] [$EXEC_HOST] using slurm for remote host resolution"

  REMOTE_HOSTS=($(sinfo | grep bibigrid | tr -s " "  | cut -d " " -f 6 | tr "," "\n"))
  IGNITE_DISCOVERY_MODE="nfs"
fi

echo "[+] [$EXEC_HOST] start distributing nextflow to ${#REMOTE_HOSTS[@]} remote hosts: ${REMOTE_HOSTS[*]}"


## Conditionally cleanup ignite discovery directory 

if [ "$PARAM_IGNITE_MODE" == "$DAEMON_MODE" ] && [ "$IGNITE_DISCOVERY_MODE" == "nfs" ]; then
  echo "[+] [$EXEC_HOST] cleaning up nf ignite discovery dir at: $PARAM_IGNITE_DISCOVERY"
  rm -rf "${PARAM_IGNITE_DISCOVERY:?}/*"
fi


## Run setup on remote hosts

for host in "${REMOTE_HOSTS[@]}"
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
  
  cmd='chmod +x ~/setup-nextflow.sh; ~/setup-nextflow.sh '"$PARAM_NF_TARGET_DIR/nextflow $PARAM_IGNITE_MODE $PARAM_IGNITE_DISCOVERY"'; exit;'

  echo "[+] [$EXEC_HOST] start setup on: $host"
  ssh -t "$SSH_HOST" "$cmd"
done

echo "[+] [$EXEC_HOST] done distributing nextflow \\o/"
