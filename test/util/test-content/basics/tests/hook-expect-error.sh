set -e

before() {
  echo "This hook executes before the test"
}

after() {
  if [[ $TEST_OUTPUT != *"command not found"* ]]; then
    echo "Failed to match expected output"
    echo $TEST_OUTPUT

    exit 1
  fi
}

"$@"
