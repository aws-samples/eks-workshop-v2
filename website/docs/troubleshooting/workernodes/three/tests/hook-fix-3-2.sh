# set -Eeuo pipefail

# before() {
#   echo "noop"
# }

# after() {
#   sleep 5

#   # Capture the pod status and handle potential errors
#   aws_node_pod=$(kubectl get pods --namespace=kube-system --selector=k8s-app=aws-node -o wide 2>&1 | grep "$NEW_NODEGROUP_3_NODE_NAME" || true)

#   if [[ -z "$aws_node_pod" ]]; then
#     echo "No aws-node pod found for node $NEW_NODEGROUP_3_NODE_NAME"
#     exit 1
#   fi

#   if [[ $aws_node_pod == *"Pending"* ]]; then
#     echo "Success: Found aws-node pod in Pending state"
#     exit 0
#   fi  

#   echo "Found pod in other state than 'Pending'"
#   exit 1
# }

# "$@"
