set -Eeuo pipefail

before() {
  echo "Asserting kro capability is ACTIVE before running Lab 3 tests..."
  status=$(aws eks describe-capability \
    --cluster-name "$EKS_CLUSTER_AUTO_NAME" \
    --capability-name "$EKS_CAP_KRO_CAPABILITY" \
    --query 'capability.status' --output text)
  if [[ "$status" != "ACTIVE" ]]; then
    echo "kro capability status is '$status', expected ACTIVE" >&2
    exit 1
  fi

  kubectl get crd resourcegraphdefinitions.kro.run >/dev/null
}

after() {
  echo "Asserting Lab 3 end state..."

  # RGD reached Active
  kubectl get rgd cartsstack \
    -o jsonpath='{.status.state}' | grep -q '^Active$'

  # Instance reached ACTIVE (kro uses uppercase for instance state, mixed
  # case for RGD state — confirmed against kro v0.9.2 shipped by the EKS
  # capability).
  kubectl get cartsstack carts-kro \
    -o jsonpath='{.status.state}' | grep -q '^ACTIVE$'

  # ACK Table inside the carts-kro namespace synced
  kubectl -n carts-kro get table.dynamodb.services.k8s.aws items \
    -o jsonpath='{.status.tableStatus}' | grep -q '^ACTIVE$'

  # AWS-side table exists
  aws dynamodb describe-table --table-name "$EKS_CAP_DDB_TABLE_KRO" \
    --query 'Table.TableStatus' --output text | grep -q ACTIVE

  # Pod Identity association for carts-kro/carts SA exists
  aws eks list-pod-identity-associations --cluster-name "$EKS_CLUSTER_AUTO_NAME" \
    --namespace carts-kro --service-account carts \
    --query 'associations[].associationId' --output text | grep -q .

  # carts Deployment from the RGD is ready (Spring Boot startup + readiness
  # probe takes 30-60s; 120s gives margin for slow image pull or scheduling).
  kubectl -n carts-kro rollout status deployment/carts --timeout=120s

  # Pod Identity creds are wired into the Pod (Pod Identity association was
  # created BEFORE the CartsStack apply, so the Pod boots with creds already).
  kubectl exec -n carts-kro deployment/carts -- env \
    | grep -q '^AWS_CONTAINER_CREDENTIALS_FULL_URI='
}

"$@"
