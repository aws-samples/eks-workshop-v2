# set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  i=0
  while ! [ "$(kubectl get ns ui -o jsonpath='{.status.phase}' --ignore-not-found=true)" == "Active" ]
  do
    sleep 5
    if [[ $i == '30' ]]
    then
      break
    fi
    ((i++))
  done
  kubectl -n ui rollout status deploy/ui
}

"$@"
