set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  timeout -s TERM 160 bash -c \
    "while [[ $(kubectl get po -n kube-system -l k8s-app=kube-dns -o json | jq -r '.items | length') -lt 3 ]];\
    do echo 'Waiting for CoreDNS to scale' && sleep 30;\
    done"

  if [ $? -ne 0 ]; then
    cat << EOF >&2
Core DNS pods did not scale up
$(kubectl get po -n kube-system -l k8s-app=kube-dns)
$(kubectl get nodes)
EOF
    exit 1
  fi
}

"$@"