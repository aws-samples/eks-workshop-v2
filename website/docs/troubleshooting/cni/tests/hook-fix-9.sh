set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 60
  
  EXIT_CODE=0

  timeout -s TERM 160 bash -c \
    'while [[ $(kubectl get pods -n cni-tshoot -o wide | grep Running | wc -l) -lt 15 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  debug=$(kubectl get pods -n cni-tshoot -o wide)
  echo "$debug"
  
  if [ $EXIT_CODE -ne 0 ]; then
    cat << EOF >&2
Some of the pods are not transition into Running state within 160 seconds
EOF
    exit 1
  fi
}

"$@"