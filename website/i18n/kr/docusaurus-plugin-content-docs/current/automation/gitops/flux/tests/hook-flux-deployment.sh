set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 30
  
  kubectl wait --for=condition=Ready --timeout=60s pods -l app.kubernetes.io/created-by=eks-workshop -n ui
}

"$@"
