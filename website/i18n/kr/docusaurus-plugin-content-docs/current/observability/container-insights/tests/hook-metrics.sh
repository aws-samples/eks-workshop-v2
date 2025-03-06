set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 300
  
  start_time=$(date -d "10 minutes ago" +"%Y-%m-%dT%H:%M:%S%z")
  end_time=$(date +"%Y-%m-%dT%H:%M:%S%z")

  num_metrics=$(aws cloudwatch get-metric-data --metric-data-queries "[{\"Id\":\"m1\",\"MetricStat\":{\"Metric\":{\"Namespace\":\"ContainerInsights\",\"MetricName\":\"pod_cpu_utilization\",\"Dimensions\":[{\"Name\":\"ClusterName\",\"Value\":\"$EKS_CLUSTER_NAME\"},{\"Name\":\"Namespace\",\"Value\":\"ui\"},{\"Name\":\"PodName\",\"Value\":\"ui\"}]},\"Period\":60,\"Stat\":\"Sum\"}}]" --start-time $start_time --end-time $end_time | jq '.MetricDataResults[0].Values | length')

  if [[ $num_metrics -lt 1 ]]; then
    >&2 echo "Only received $num_metrics"
    exit 1
  fi
}

"$@"