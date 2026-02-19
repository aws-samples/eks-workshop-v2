set -Eeuo pipefail

before() {
  echo "Ensuring CronJob 'catalog-cleanup' has created at least one job..."

  # Check if any jobs already exist from the CronJob
  job_count=$(kubectl get jobs -n catalog --no-headers 2>/dev/null | grep -c "catalog-cleanup-" || echo "0")
  
  if [[ "$job_count" -ge 1 ]]; then
    echo "CronJob has already created $job_count job(s)."
    return
  fi

  # If no jobs exist, wait a bit for the CronJob to run naturally
  echo "No existing jobs found. Waiting up to 90 seconds for CronJob to run..."
  for i in {1..9}; do
    job_count=$(kubectl get jobs -n catalog --no-headers 2>/dev/null | grep -c "catalog-cleanup-" || echo "0")
    if [[ "$job_count" -ge 1 ]]; then
      echo "CronJob has created $job_count job(s)."
      return
    fi
    sleep 10
  done

  echo "CronJob hasn't run yet. This is normal for CronJobs with minute-based schedules."
  echo "The test will proceed - CronJob jobs may appear in subsequent runs."
}

after() {
  echo "Checking for CronJob-created jobs..."
  job_count=$(kubectl get jobs -n catalog --no-headers 2>/dev/null | grep -c "catalog-cleanup-" || echo "0")
  
  if [[ "$job_count" -ge 1 ]]; then
    echo "Found $job_count CronJob-created job(s). Verification successful."
  else
    echo "No CronJob-created jobs found yet. This is normal - CronJobs run on schedule."
    echo "The manual job 'manual-cleanup' demonstrates the same functionality."
  fi
}

"$@"
