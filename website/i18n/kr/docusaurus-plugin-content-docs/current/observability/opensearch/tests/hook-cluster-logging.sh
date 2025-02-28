set -e

before() {
  echo "noop"
}

after() {
  logging_check=$(aws eks describe-cluster --region $AWS_REGION --name $EKS_CLUSTER_NAME --output json | jq -r '.cluster.logging.clusterLogging[0].enabled')

  if [[ "$logging_check" != "true" ]]; then
    echo 'Error: Cluster logging configuration not as expected'
    aws eks describe-cluster --region $AWS_REGION --name $EKS_CLUSTER_NAME
    exit 1
  fi
}

"$@"
