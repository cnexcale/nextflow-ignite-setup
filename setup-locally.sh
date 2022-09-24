#!/bin/bash
PARAM_MODE="$1"
PARAM_NF_BASE="$2"
DEFAULT_BASE="$HOME/nf-current"


if [ "$PARAM_MODE" == "" ]; then
  echo "[-] setup mode required: from-local, from-git"
  exit 1
fi


NF_TARGET=""
if [ "$PARAM_NF_BASE" == "" ]; then
  echo "[~] nextflow source dir is missing, using default $DEFAULT_SOURCE"
  NF_TARGET="$DEFAULT_BASE"
else
  NF_TARGET="$2"
fi


SCRIPT=""
if [ "$PARAM_MODE" == "from-local" ]; then
  SCRIPT="./helper/setup-nextflow.sh"
  NF_TARGET="$BASE/nextflow"
else
  SCRIPT="./helper/setup-nextflow.git.sh"
fi


bash "$SCRIPT" "$NF_TARGET"
