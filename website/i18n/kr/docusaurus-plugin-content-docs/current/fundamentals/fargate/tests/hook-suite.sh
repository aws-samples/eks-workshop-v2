set -e

before() {
  echo "noop"
}

after() {
  prepare-environment

  aws eks wait fargate-profile-deleted --cluster-name $EKS_CLUSTER_NAME --fargate-profile-name checkout-profile
}

"$@"
