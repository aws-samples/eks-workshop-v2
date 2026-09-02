set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl wait --for=condition=Ready --timeout=120s pods \
    -l app.kubernetes.io/name=eks-pod-identity-agent -n kube-system
}

"$@"
