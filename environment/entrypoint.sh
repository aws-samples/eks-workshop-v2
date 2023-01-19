#!/bin/bash

set -e

# TODO: Move to .bashrc or similar
export AWS_PAGER=""

bash /prepare.sh

if [ $# -eq 0 ]
  then
    bash -l
else
  bash -c "$@"
fi
