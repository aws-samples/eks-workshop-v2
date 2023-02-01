before() {
  echo "noop"
}

after() {
  kubectl delete dbinstance.rds.aws.crossplane.io --all
}

"$@"
