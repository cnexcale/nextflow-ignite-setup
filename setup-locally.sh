#!/bin/bash
PARAM_NF_SOURCE="$1"

if [ "$PARAM_NF_SOURCE" == "" ]; then
  echo "[-] nextflow source dir is missing!"
  exit 1
fi

./setup-nextflow.sh ~/nf-current/nextflow