#!/bin/bash
PARAM_NF_SOURCE="$1"
DEFAULT_SOURCE="~/nf-current"

SOURCE=""
if [ "$PARAM_NF_SOURCE" == "" ]; then
  echo "[~] nextflow source dir is missing, using default $DEFAULT_SOURCE"
  SOURCE="$DEFAULT_SOURCE"
else
  SOURCE="$1"
fi

./setup-nextflow.sh "$SOURCE"
