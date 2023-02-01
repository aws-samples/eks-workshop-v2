set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl delete dbinstance.rds.services.k8s.aws --all -n catalog

  aws rds wait db-instance-deleted --db-instance-identifier ${EKS_CLUSTER_NAME}-catalog-ack
}

"$@"
