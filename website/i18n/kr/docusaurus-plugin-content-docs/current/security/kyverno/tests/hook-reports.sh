set -Eeuo pipefail

before() {
  sleep 180
}

after() {
  echo "noop"
}

"$@"
