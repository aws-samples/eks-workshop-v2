set -Eeuo pipefail

before() {
  echo "noop"
}

after() {

  aws_node=$(kubectl get pods --selector=k8s-app=aws-node -n kube-system -o json | jq -r '.items[].metadata.name' | wc -l)

  if [[ $aws_node -lt 1 ]]; then
    >&2 echo "AWS Node deployed incorrectly"
    exit 1
  fi
}

"$@"
