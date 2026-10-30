set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  if [[ $TEST_OUTPUT != *"timed out waiting"* ]]; then
    echo "Failed to match expected output"
    echo $TEST_OUTPUT

    exit 1
  fi
}

"$@"
