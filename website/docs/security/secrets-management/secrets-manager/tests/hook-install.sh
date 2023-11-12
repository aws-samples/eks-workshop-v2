set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl wait --for condition=established --timeout=120s crd secretproviderclasses.secrets-store.csi.x-k8s.io
}

"$@"
