#!/bin/bash

environment=$1
shell_command=$2

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Launching IDE on 127.0.0.1:8080"

bash $SCRIPT_DIR/shell.sh "$environment" code-server