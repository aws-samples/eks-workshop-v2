set -Eeuo pipefail

before() {
  echo "Asserting ACK capability is ACTIVE before running ACK lab tests..."
  status=$(aws eks describe-capability \
    --cluster-name "$EKS_CLUSTER_AUTO_NAME" \
    --capability-name "$EKS_CAP_ACK_CAPABILITY" \
    --query 'capability.status' --output text)
  if [[ "$status" != "ACTIVE" ]]; then
    echo "ACK capability status is '$status', expected ACTIVE" >&2
    exit 1
  fi

  kubectl get crd tables.dynamodb.services.k8s.aws >/dev/null
}

after() {
  echo "Asserting ACK lab end state..."

  # Table exists in AWS
  aws dynamodb describe-table --table-name "$EKS_CAP_DDB_TABLE" \
    --query 'Table.TableStatus' --output text | grep -q ACTIVE

  # Pod Identity association for carts SA exists
  aws eks list-pod-identity-associations --cluster-name "$EKS_CLUSTER_AUTO_NAME" \
    --namespace carts --service-account carts \
    --query 'associations[].associationId' --output text | grep -q .

  # carts Pod sees the new table name in its environment
  kubectl exec -n carts deployment/carts -- env \
    | grep -q "^RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME=${EKS_CAP_DDB_TABLE}$"
}

"$@"
