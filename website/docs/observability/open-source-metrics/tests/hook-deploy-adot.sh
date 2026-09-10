set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  # The cluster-scraper needs a moment after the add-on becomes active to start,
  # scrape its targets and remote-write to AMP. Poll the workspace until the "up"
  # metric for a scraped application namespace appears, up to three minutes.
  found=""
  for _ in $(seq 1 18); do
    check=$(awscurl -X POST --region "${AWS_REGION}" --service aps \
      "${AMP_ENDPOINT}api/v1/query?query=up" 2>/dev/null \
      | jq '.data.result[] | select(.metric.namespace=="carts")' 2>/dev/null || true)
    if [ -n "$check" ]; then
      found="yes"
      break
    fi
    sleep 10
  done

  if [ -z "$found" ]; then
    echo "Error: Did not find metrics in AMP"
    exit 1
  fi
}

"$@"
