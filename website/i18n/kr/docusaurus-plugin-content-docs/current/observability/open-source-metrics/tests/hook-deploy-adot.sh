set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 80

  check=$(awscurl -X POST --region ${AWS_REGION} --service aps "${AMP_ENDPOINT}api/v1/query?query=up" | jq '.data.result[] | select(.metric.namespace=="carts")')

  if [ -z "$check" ]; then
    echo "Error: Did not find metrics in AMP"
    exit 1
  fi
}

"$@"
