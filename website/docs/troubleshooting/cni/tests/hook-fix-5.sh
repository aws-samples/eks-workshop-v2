set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 60

  echo "Recycle aws-node pod for faster response"
  kubectl delete pods -n kube-system -l k8s-app=aws-node
  
  EXIT_CODE=0

  timeout -s TERM 160 bash -c \
    'while [[ $(kubectl get nodes | grep NotReady | wc -l) -gt 0 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  debug=$(kubectl get nodes)
  echo "$debug"
  
  if [ $EXIT_CODE -ne 0 ]; then
    cat << EOF >&2
One of the worker nodes is still in NotReady state within 160 seconds
EOF
    exit 1
  fi
}

"$@"