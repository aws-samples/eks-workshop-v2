set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  prepare-environment

  sleep 60

  kubectl delete -k /eks-workshop/manifests/base-application --all

  sleep 60
}

"$@"
