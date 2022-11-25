set -Eeuo pipefail

before() {
  echo "This hook executes before the suite"
}

after() {
  echo "This hook executes after the suite"
}

"$@"