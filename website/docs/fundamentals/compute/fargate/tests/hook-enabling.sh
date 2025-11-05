before() {
  echo "noop"
}

after() {
  aws eks wait fargate-profile-active --cluster-name ${EKS_CLUSTER_NAME} \
    --fargate-profile-name checkout-profile
    
  check=$(kubectl get po -n checkout -l app.kubernetes.io/instance=checkout,app.kubernetes.io/component=service -o json | jq -r '.items[0].spec.nodeName' | grep 'fargate' || true)

  if [ -z "$check" ]; then
    echo "checkout pod not scheduled on fargate"
    kubectl get po -n checkout -l app.kubernetes.io/instance=checkout,app.kubernetes.io/component=service -o json | jq '.'
    aws eks describe-fargate-profile --cluster-name ${EKS_CLUSTER_NAME} \
      --fargate-profile-name checkout-profile
    exit 1
  fi
}

"$@"
