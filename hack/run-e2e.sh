#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Creating/updating infrastructure..."

bash $SCRIPT_DIR/create-infrastructure.sh "$@"

bash $SCRIPT_DIR/run-tests.sh "$@"

bash $SCRIPT_DIR/destroy-infrastructure.sh "$@"