set -Eeuo pipefail

before() {
  mkdir -p /home/ec2-user/.ssh
}

after() {
  echo "noop"
}

"$@"
