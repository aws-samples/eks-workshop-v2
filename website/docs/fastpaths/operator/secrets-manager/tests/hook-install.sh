set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 120
  kubectl wait --for condition=established --timeout=120s crd secretproviderclasses.secrets-store.csi.x-k8s.io
}

"$@"
