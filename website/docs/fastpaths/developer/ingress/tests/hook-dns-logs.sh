set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  if [[ $TEST_OUTPUT != *"Desired change: CREATE ui.retailstore.com"* ]]; then
    >&2 echo "Failed to match expected output"
    echo $TEST_OUTPUT
    exit 1
  fi
}

"$@"
