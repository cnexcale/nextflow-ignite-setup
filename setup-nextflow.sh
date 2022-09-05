#!/bin/bash -e

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# SUMMARY
#
#   This script performs a local setup of nextflow. It does so by compiling
#   nextflow from source and explicitly builds the plugin modules which are 
#   copied to the standard plugin cache of nextflow (~/.nextflow/plugins).
#
#   This allows running nextflow with patched plugins which otherwise would
#   be downloaded from a plugin index (https://github.com/nextflow-io/plugins)
#   and used over any plugin customizations.
#
#   Furthermore this setup script installs Java and make (if not present) 
#   in order to build nextflow from source.
#   Check/adjust $JAVA_VER for the Java version that is to be installed.  
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# A WORD OF WARNING
#
#   Since ~/.nextflow and ~/.gradle are used to cache build artifacts or 
#   downloaded sources/binaries/packages both directories will be purged 
#   during script execution!
#   Remove respective lines in the script if this is not desired.
#   
#   The script also kills all running ignite daemons on the local machine
#   to ensure that only one daemon node is active
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# USAGE
#
# ./setup-nextflow.sh <nextflow_source_dir> <ignite_discovery_dir> <mode>
#   nextflow_source_dir   := root of nextflow repository (top level Makefile)
#   ignite_discovery_dir  := common dir on shared nfs for all ignite daemons
#   mode                  := use "daemon" to start an ignite daemon or omit
#                            if setting up the master node
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


PARAM_NEXTFLOW_DIR="$1"
PARAM_IGNITE_MODE="$2"
PARAM_IGNITE_DISCOVERY="$3"

HOST="$(hostname)"
JAVA_VER="openjdk-11-jre-headless"

## Constants

DAEMON_MODE="daemon"


## Checking parameters

if [ "$PARAM_NEXTFLOW_DIR" == "" ]; then
  echo "[-] nextflow source directory is missing!"
  echo '    usage: ./setup-nextflow.sh <nextflow_source_dir> <ignite_discovery_dir> <mode>'
  exit 1
fi

if [ "$PARAM_IGNITE_MODE" == "$DAEMON_MODE" ]; then

  if [ "$PARAM_IGNITE_DISCOVERY" == "" ]; then
    echo "[-] daemon mode specified but discovery dir for ignite is missing!"
    echo '    usage: ./setup-nextflow.sh <nextflow_source_dir> <ignite_discovery_dir> <mode>'
    exit 1
  fi

  echo "[~] daemon flag received, will start nextflow ignite daemon after setup"
  echo "[~] will use discovery for ignite daemons: $PARAM_IGNITE_DISCOVERY"
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

echo "[+] [$HOST] cleanup all nf binaries and gradle cache"
rm -rf ~/.nextflow
rm -rf ~/.gradle

echo "[+] [$HOST] cd into nf dir: $PARAM_NEXTFLOW_DIR"
cd "$PARAM_NEXTFLOW_DIR"

echo "[+] [$HOST] clean cache, build and temp files"
make clean > /dev/null


## Start building nextflow modules and plugins

echo "[+] [$HOST] build project to get compiled plugins"
make assemble > /dev/null

echo "[+] [$HOST] copying built plugins into nextflows plugin resolve dir"
cp -r build/plugins ~/.nextflow/plugins

echo "[+] [$HOST] installing nextflow"
make install > /dev/null


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

  if [ "$IGNITE_DISCOVERY_MODE" == "ip" ]; then
    # use `nohup` to prevent nextflow ignite deamons being killed on ssh session termination
    echo "[+] [$HOST] join ignite cluster via IP at $PARAM_IGNITE_DISCOVERY"
    export NXF_PLUGINS_DEFAULT=nf-ignite; nohup "$PARAM_NEXTFLOW_DIR/nextflow" node -bg -cluster.join ip:"$PARAM_IGNITE_DISCOVERY"
  else
    # use `nohup` to prevent nextflow ignite deamons being killed on ssh session termination
    echo "[+] [$HOST] join ignite cluster via shared NFS at $PARAM_IGNITE_DISCOVERY"
    export NXF_PLUGINS_DEFAULT=nf-ignite; nohup "$PARAM_NEXTFLOW_DIR/nextflow" node -bg -cluster.join path:"$PARAM_IGNITE_DISCOVERY"
  fi

fi

echo "[+] [$HOST] done with nextflow setup"

exit