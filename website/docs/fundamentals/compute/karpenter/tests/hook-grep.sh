set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  if [[ -z "$TEST_OUTPUT" ]]; then
    echo "Failed to find a disruption log. Expected at least one."
    exit 1
  fi
}

"$@"
