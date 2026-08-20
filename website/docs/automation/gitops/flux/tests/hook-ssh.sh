set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  echo "noop"
}

"$@"
