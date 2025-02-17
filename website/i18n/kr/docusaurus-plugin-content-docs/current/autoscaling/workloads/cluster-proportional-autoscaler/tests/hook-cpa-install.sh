before() {
  echo "noop"
}

after() {
  EXIT_CODE=0

  timeout -s TERM 300 bash -c \
    'while [[ $(kubectl get configmap -n kube-system | grep dns-autoscaler | wc -l) -ne 1 ]];\
    do sleep 30;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    cat << EOF >&2
DNS autoscaler ConfigMap not created
------
$(kubectl get configmap -n other)
EOF
    exit 1
  fi
}

"$@"
