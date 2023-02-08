before() {
  kubectl -n catalog delete secret catalog-rds-pw || true
}

after() {
 echo "noop"
}

"$@"
