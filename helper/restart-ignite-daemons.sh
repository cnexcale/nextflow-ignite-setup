#!/bin/bash


PARAM_HOSTS="$1"
PARAM_NF_DIR="$2"


if [ "$PARAM_HOSTS" == "" ]; then
  echo "[-] host list is missing"
  exit 1
fi

if [ "$PARAM_NF_DIR" == "" ]; then
  echo "[-] Nextflow directory is missing"
  exit 1
fi


IFS=',' read -ra REMOTE_HOSTS <<< $PARAM_HOSTS

echo "[+] will run $PARAM_SCRIPT on ${#REMOTE_HOSTS[@]}"

for host in "${REMOTE_HOSTS[@]}"
do

  SSH_HOST="ubuntu@$host"

  echo "[+] [$host] trying to find and kill running nf ignite deamons"

  # parse ps output to find possible running nextflow ignite instances
  # exclude grep'ing processes
  PIDS=$( ssh "$SSH_HOST" 'echo $(ps -aux | grep "bin/java.*nextflow.cli.Launcher.*-cluster\.join" | grep -v "grep" | tr -s " " | cut -d " " -f 2 | tr "\n" " ")' )

  if [ "$PIDS" == " " ] || [ "$PIDS" == "" ]; then
      echo "[+] [$host] didnt find any ignite deamons running"
  else
      echo "[+] [$host] found deamons: $PIDS"
      ssh "$SSH_HOST" 'kill -9 '"$PIDS"' '
  fi

  # run from exec dir so log file will be placed there by ignite daemon
  cd "$PARAM_NF_DIR"

  # use `nohup` to prevent nextflow ignite deamons being killed on ssh session termination
  echo "[+] [$host] join ignite cluster via IP at $PARAM_HOSTS"
  ssh $SSH_HOST 'export NXF_PLUGINS_DEFAULT=nf-ignite,nf-amazon; nohup '"$PARAM_NF_DIR/nextflow"' node -bg -cluster.join ip:'"$PARAM_HOSTS"''

  if [[ $? -ne 0 ]]; then
    echo "[-] ERROR: $host did not complete successfully"
  else
    echo "[+] $host complete"
  fi

done
