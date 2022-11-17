set -Eeuo pipefail

before() {
  EXIT_CODE=0
 
  timeout -s TERM 300 bash -c \
    'while [[ $(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_TAINTED_MNG_NAME |  jq --raw-output .nodegroup.status) != "ACTIVE" ]];\
    do sleep 10;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Node group was not ready in 5 minutes"
    exit 1
  fi
  
}

after() {

  EXIT_CODE=0
  
  timeout -s TERM 300 bash -c \
    'while [[ $(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_TAINTED_MNG_NAME |  jq --raw-output .nodegroup.status) != "ACTIVE" ]];\
    do sleep 10;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Node group was not ready in 5 minutes"
    exit 1
  fi
}

"$@"