set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  if [[ $TEST_OUTPUT != *"1ca35e86-4b4c-4124-b6b5-076ba4134d0d.jpg"* ]]; then
    >&2 echo "Failed to match expected output"
    echo $TEST_OUTPUT
    exit 1
  fi
}

"$@"
