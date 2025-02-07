set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 20

  number_of_subnets=$(aws ec2 describe-subnets --filters 'Name=tag:kubernetes.io/role/elb,Values=1' --query 'Subnets[].SubnetId' --output json | jq 'length')
  
  echo "# of subnets: ${number_of_subnets}"
  
  output_message=$(kubectl describe ingress/ui -n ui)

  if [[ $output_message == *"Failed deploy model due to AccessDenied"* ]]; then
    >&2 echo "text Not found: Failed deploy model due to AccessDenied"
    exit 1
  fi

  EXIT_CODE=0
}

"$@"
