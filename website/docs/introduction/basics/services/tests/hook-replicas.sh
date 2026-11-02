set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  kubectl rollout status -n ui deployment/ui --timeout=60s
  
  # Wait for all 3 pods to be ready
  kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ui -n ui --timeout=60s

  POD_COUNT=$(kubectl get pod -n ui -l app.kubernetes.io/name=ui -o json | jq -r ".items | length")
  
  if [[ $POD_COUNT -ne 3 ]]; then
    >&2 echo "There should be 3 pods running"
    exit 1
  fi

  # The ui container has no readinessProbe, so a new pod is marked Ready (and
  # added to the Service endpoints) as soon as the container starts, before the
  # app listens on 8080. Wait until the Service lists 3 ready endpoints and each
  # of them answers from test-pod, so the next load-balancing loop on the page
  # doesn't hit a pod that refuses connections.
  for attempt in $(seq 1 60); do
    IPS=$(kubectl get endpointslice -n ui -l kubernetes.io/service-name=ui -o json \
      | jq -r '[.items[].endpoints[]? | select(.conditions.ready == true) | .addresses[]] | unique | .[]')
    COUNT=$(echo "$IPS" | grep -c . || true)

    if [[ $COUNT -eq 3 ]]; then
      ALL_OK=1
      for ip in $IPS; do
        if ! kubectl exec test-pod -- curl -sf --max-time 3 "http://${ip}:8080/actuator/info" > /dev/null 2>&1; then
          ALL_OK=0
          break
        fi
      done

      if [[ $ALL_OK -eq 1 ]]; then
        echo "All 3 ui endpoints are serving"
        exit 0
      fi
    fi

    sleep 5
  done

  >&2 echo "ui endpoints did not all start serving in time"
  exit 1
}

"$@"
