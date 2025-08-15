set -Eeuo pipefail

before() {
  mkdir -p ~/.ssh/
  ssh-keyscan -p 2222 $GITEA_SSH_HOSTNAME &> ~/.ssh/known_hosts
}

after() {
  echo "noop"
}

"$@"
