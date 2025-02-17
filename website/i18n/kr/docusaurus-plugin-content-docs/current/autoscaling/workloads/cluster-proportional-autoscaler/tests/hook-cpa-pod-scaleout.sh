before() {
  echo "noop"
}

after() {
  EXIT_CODE=0

  timeout -s TERM 240 bash -c \
    'while [[ $(kubectl get po -n kube-system -l k8s-app=kube-dns -o json | jq -r ".items | length") -lt 3 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    cat << EOF >&2
Core DNS pods did not scale up
$(kubectl get po -n kube-system -l k8s-app=kube-dns)
$(kubectl get nodes)
EOF
    exit 1
  fi
}

"$@"
