#!/bin/bash -e


PARAM_NF_BASE_DIR="$1"
PARAM_IGNITE_MODE="$2"
PARAM_IGNITE_DISCOVERY="$3"

HOST="$(hostname)"
JAVA_VER="openjdk-11-jre-headless"

## Constants

DAEMON_MODE="daemon"


## Checking parameters

if [ "$PARAM_NF_BASE_DIR" == "" ]; then
  echo "[-] setup base directory is missing!"
  echo '    usage: ./setup-nextflow.sh <setup_base_dir> <ignite_discovery_dir> <mode>'
  exit 1
fi

if [ "$PARAM_IGNITE_MODE" == "$DAEMON_MODE" ]; then

  if [ "$PARAM_IGNITE_DISCOVERY" == "" ]; then
    echo "[-] daemon mode specified but discovery dir for ignite is missing!"
    echo '    usage: ./setup-nextflow.sh <nextflow_source_dir> <ignite_discovery_dir> <mode>'
    exit 1
  fi

  echo "[~] [$HOST] daemon flag received, will start nextflow ignite daemon after setup"
  echo "[~] [$HOST] will use discovery for ignite daemons: $PARAM_IGNITE_DISCOVERY"
fi


## Checking Java

echo "[+] [$HOST] checking if java is installed"

if ! command -v java &> /dev/null; then
  echo "[~] [$HOST] java not found, installing $JAVA_VER"
  sudo apt update --yes
  sudo apt install --yes $JAVA_VER
fi


## Checking make

printf "[+] [%s] checking if make is installed\n" "$HOST"

if ! command -v make &> /dev/null; then
  printf "[~] [%s] make not found, installing\n" "$HOST"
  sudo apt update --yes
  sudo apt install --yes make
fi


echo "[+] [$HOST] starting nextflow setup"


## Check discovery mode

IP_REGEX="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]{1,5})?"

if [[ $PARAM_IGNITE_DISCOVERY =~ $IP_REGEX ]]; then
  IGNITE_DISCOVERY_MODE="ip"
else
  IGNITE_DISCOVERY_MODE="nfs"
fi


## Cleanup

echo "[+] [$HOST] cleanup existing nf binaries and gradle cache"
rm -rf ~/.nextflow
rm -rf ~/.gradle


# Nextfow setup

NF_EXEC_DIR="$PARAM_NF_BASE_DIR/nextflow"

echo "[+] [$HOST] setup nextflow executable dir: $NF_EXEC_DIR"
mkdir -p "$NF_EXEC_DIR"
cd "$NF_EXEC_DIR"
curl -fsSL https://get.nextflow.io | bash


# nf-ignite Setup

NF_IGNITE_DIR="$PARAM_NF_BASE_DIR/nf-ignite"
echo "[+] [$HOST] setting up nf-ignite plugin"
cd "$PARAM_NF_BASE_DIR"
rm -r "$NF_IGNITE_DIR"
git clone https://github.com/cnexcale/nf-ignite.git
cd "$NF_IGNITE_DIR"
git checkout develop-mot
echo "[+] [$HOST] building plugin"
./gradlew assemble > /dev/null
cp -r build/plugins ~/.nextflow/plugins/


## Conditionally start nextflow ignite daemon

if [ "$PARAM_IGNITE_MODE" == "$DAEMON_MODE" ]; then
  echo "[+] [$HOST] trying to find and kill running nf ignite deamons"
  
  # parse ps output to find possible running nextflow ignite instances
  # exclude grep'ing processes
  PIDS=$(ps -aux | grep "bin/java.*nextflow.cli.Launcher.*-cluster\.join" | grep -v "grep" | tr -s " " | cut -d " " -f 2 | tr "\n" " ")

  if [ "$PIDS" == " " ] || [ "$PIDS" == "" ]; then
    echo "[+] [$HOST] didnt find any ignite deamons running"
  else
    echo "[+] [$HOST] found deamons: $PIDS"
    kill $PIDS
  fi

  # run from exec dir so log file will be put placed there by ignite daemon
  cd "$NF_EXEC_DIR"

  if [ "$IGNITE_DISCOVERY_MODE" == "ip" ]; then
    # use `nohup` to prevent nextflow ignite deamons being killed on ssh session termination
    echo "[+] [$HOST] join ignite cluster via IP at $PARAM_IGNITE_DISCOVERY"
    nohup "$NF_EXEC_DIR/nextflow" node -bg -cluster.join ip:"$PARAM_IGNITE_DISCOVERY"
  else
    # use `nohup` to prevent nextflow ignite deamons being killed on ssh session termination
    echo "[+] [$HOST] join ignite cluster via shared NFS at $PARAM_IGNITE_DISCOVERY"
    nohup "$NF_EXEC_DIR/nextflow" node -bg -cluster.join path:"$PARAM_IGNITE_DISCOVERY"
  fi

fi

echo "[+] [$HOST] done with nextflow setup"

exit