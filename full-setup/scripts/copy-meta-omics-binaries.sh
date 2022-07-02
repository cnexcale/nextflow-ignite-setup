#!/bin/bash

if [ "$1" == "" ]; then
  echo "[-] no source dir param for meta-omics binaries"
  exit 0
fi

BINARY_SRC="$1/*"
echo "[+] will use $BINARY_SRC as source for binaries to copy"

if [ "$2" == "" ]; then
  echo "[-] no host list param"
  exit 0
fi

# split ","-separated list of target hosts into HOSTS array
IFS=',' read -ra HOSTS <<< "$2"

if [ ${#HOSTS[@]} == 0 ]; then
  echo "[-] host list is empty"
  exit 0
fi

echo "[+] received list of ${#HOSTS[@]} hosts"

TOOLS_DIR="/home/ubuntu/meta-tools"

for host in "${HOSTS[@]}"
do
  echo "[+] creating tools dir on host $host"
  ssh -t ubuntu@$host 'mkdir '"$TOOLS_DIR"''
  echo "[+] copying binaries from meta-omics-toolkit folder"
  scp $BINARY_SRC ubuntu@$host:"$TOOLS_DIR"
  echo "[+] done on host $host"
done

echo "[+] done"
