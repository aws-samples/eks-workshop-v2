set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  EXIT_CODE=0
  
  timeout -s TERM 120 bash -c \
    'while [[ $(kubectl get pod -l app.kubernetes.io/instance=ui -n ui -o json | jq -r ".items | length") -lt 3 ]];\
    do sleep 10;\
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "Application did not scale within 120 seconds"
    exit 1
  fi
}

"$@"
