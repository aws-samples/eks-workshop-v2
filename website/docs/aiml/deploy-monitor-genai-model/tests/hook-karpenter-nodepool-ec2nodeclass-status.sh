set -e

before() {
  echo "noop"
}



after() {
  
# Set the Karpenter namespace
NAMESPACE="karpenter"

# Check if the Karpenter nodepool exists
if ! kubectl get nodepool -n "$NAMESPACE" &> /dev/null; then
  echo "Karpenter nodepool not found in namespace '$NAMESPACE'"
  exit 1
fi

# Check if the Karpenter EC2 nodeclass exists
if ! kubectl get ec2nodeclass -n "$NAMESPACE" &> /dev/null; then
  echo "Karpenter EC2 nodeclass not found in namespace '$NAMESPACE'"
  exit 1
fi

echo "Karpenter nodepool and EC2 nodeclass found in namespace '$NAMESPACE'"
exit 0

}

"$@"
