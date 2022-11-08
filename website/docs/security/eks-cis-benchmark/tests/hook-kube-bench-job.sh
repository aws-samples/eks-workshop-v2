set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10


  job_success=$(kubectl wait --for=condition=complete --timeout=60s job/kube-bench -n default)
  job_debug_success=$(kubectl wait --for=condition=complete --timeout=60s job/kube-bench-debug -n default)

  if [[ $job_success != "job.batch/kube-bench condition met" ]]; then
    >&2 echo "Job did not complete"

    exit 1
  fi

    if [[ $job_debug_success != "job.batch/kube-bench-debug condition met" ]]; then
    >&2 echo "Debug Job didn't complete"

    exit 1
  fi
}

"$@"
