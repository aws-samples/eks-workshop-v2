set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  if [[ $TEST_OUTPUT != *"HTTP/1.1 200 OK"* ]]; then
    >&2 echo "Failed to match expected output"
    echo $TEST_OUTPUT
    exit 1
  fi
}

"$@"
