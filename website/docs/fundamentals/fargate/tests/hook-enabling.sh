before() {
  echo "noop"
}

after() {
  kubectl rollout status -n checkout deployment/checkout --timeout=200s
}

"$@"
