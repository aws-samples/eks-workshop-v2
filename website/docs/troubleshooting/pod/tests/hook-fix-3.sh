set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  # Initial sleep before starting the check cycles
  sleep 120

  # Maximum number of attempts (adjust as needed)
  max_attempts=10
  attempt=1

  while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt of $max_attempts: Checking if at least 1 pod is running..."
    
    # Count the number of running pods with the selector
    kubectl get pods -l app=efs-app
    echo "+++++++"
    kubectl get pods -l app=efs-app -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'
    running_pods=$(kubectl get pods -l app=efs-app -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null | wc -w)
    
    if [ "$running_pods" -ge 1 ]; then
      echo "Success: Found $running_pods pod(s) with selector 'app=efs-app' in running state"
      exit 0
    fi
    
    echo "Pod not yet running. Waiting for 1 minute before next check..."
    
    # Exit the loop on the last attempt
    if [ $attempt -eq $max_attempts ]; then
      break
    fi
    
    # Wait for 1 minute before next attempt
    sleep 60
    ((attempt++))
  done

  >&2 echo "pod is not in running state, when expected to be running"
  exit 1
}



"$@"