set -e

before() {
  echo "noop"
}

after() {
  if [[ $TEST_OUTPUT != *"completion_tokens"* ]]; then
    >&2 echo "Failed to match expected output"
    echo $TEST_OUTPUT
    exit 1
  fi
}

"$@"
