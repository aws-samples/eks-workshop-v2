#!/bin/bash

environment_name=$1
module=$2

set -Eeuo pipefail
set -u

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export TEST_REPORT=1
export RESOURCES_PRECREATED='true'

exit_code=0

bash $SCRIPT_DIR/run-tests.sh "$environment_name" "$module" '-' || exit_code=$?

(cd $SCRIPT_DIR/../test/timings && npm run exec $module)

exit $exit_code