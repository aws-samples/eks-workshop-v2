set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 60

  EXIT_CODE=0

  timeout -s TERM 160 bash -c \
    'while [[ $(kubectl get pods -n kube-system -l k8s-app=aws-node -o wide | grep Pending | wc -l) -gt 0 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  debug=$(kubectl get pods -n kube-system -l k8s-app=aws-node -o wide)
  echo "$debug"

  if [ $EXIT_CODE -ne 0 ]; then
    cat << EOF >&2
One of the aws-node is still in Pending state within 160 seconds
EOF
    exit 1
  fi
}

"$@"