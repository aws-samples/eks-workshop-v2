set -Eeuo pipefail

before() {
  GITEA_SSH_HOSTNAME=$(kubectl get svc -n gitea gitea-ssh -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
  
  mkdir -p ~/.ssh/
  ssh-keyscan -p 2222 $GITEA_SSH_HOSTNAME &> ~/.ssh/known_hosts
}

after() {
  echo "noop"
}

"$@"
