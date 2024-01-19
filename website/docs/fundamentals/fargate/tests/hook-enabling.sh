before() {
  echo "noop"
}

after() {
  check=$(kubectl get po -n checkout -l app.kubernetes.io/instance=checkout,app.kubernetes.io/component=service -o json | jq -r '.items[0].spec.nodeName' | grep 'fargate' || true)

  if [ -z "$check" ]; then
    echo "checkout pod not scheduled on fargate"
    kubectl get po -n checkout -l app.kubernetes.io/instance=checkout,app.kubernetes.io/component=service -o json | jq
    exit 1
  fi
}

"$@"
