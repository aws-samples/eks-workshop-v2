set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  echo "Developer essentials complete"
}

"$@"
