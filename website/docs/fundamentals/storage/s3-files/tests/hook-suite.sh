set -e

before() {
  echo "noop"
}

after() {
  prepare-environment
}

"$@"
