set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  i=0
  while ! [ "$(kubectl get ns ui -o jsonpath='{.status.phase}' --ignore-not-found=true)" == "Active" ]
  do
    sleep 2
    if [[ $i == '60' ]]
    then
      break
    fi
    ((i++))
  done
  kubectl wait --for=condition=Ready --timeout=60s pods -l app.kubernetes.io/created-by=eks-workshop -n ui
}

"$@"
