set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  export route_table_output=$(aws ec2 describe-route-tables --route-table-ids $NEW_NODEGROUP_2_ROUTETABLE_ID --query 'RouteTables[0].Routes')

  if [[ $route_table_output == *"NatGatewayId"* ]]; then
    >&2 echo "Found NatGatewayId when it should not exist"
    exit 1
  fi  
  exit 0
}

"$@"
