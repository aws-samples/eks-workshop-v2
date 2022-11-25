set -Eeuo pipefail

before() {
  echo "This hook executes before the test"
}

after() {
  echo "This hook executes after the test"
}

"$@"