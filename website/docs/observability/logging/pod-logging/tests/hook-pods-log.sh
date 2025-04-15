set -e

before() {
  echo "fluent-bit log in progress"
  echo "noop"
}

after() {
  sleep 10
  echo "fluent-bit log in progress"
  if [[ $TEST_OUTPUT != *"Created log stream"* ]]; then
    echo "Failed to match expected output"
    echo $TEST_OUTPUT
    exit 1
  fi
}

"$@"