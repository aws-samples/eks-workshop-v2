set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  echo "Pod logging lab complete"
}

"$@"
