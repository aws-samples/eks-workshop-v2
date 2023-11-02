set -e

before() {
  kubectl wait --for condition=established --timeout=2m crd/tables.dynamodb.aws.upbound.io
}

after() {
  echo "noop"
}

"$@"
