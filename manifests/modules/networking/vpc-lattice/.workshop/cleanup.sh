#!/bin/bash

set -e

echo "Deleting VPC Lattice routes and gateway..."

kubectl delete namespace checkoutv2 --ignore-not-found > /dev/null

kubectl delete -f ~/environment/eks-workshop/modules/networking/vpc-lattice/routes --ignore-not-found > /dev/null
cat ~/environment/eks-workshop/modules/networking/vpc-lattice/controller/eks-workshop-gw.yaml | envsubst | kubectl delete --ignore-not-found -f - > /dev/null
kubectl delete -f ~/environment/eks-workshop/modules/networking/vpc-lattice/controller/gatewayclass.yaml --ignore-not-found > /dev/null

echo "Waiting for VPC Lattice target groups to be deleted..."

timeout -s TERM 300 bash -c \
    'while [[ ! -z "$(aws vpc-lattice list-target-groups --output text | grep 'checkout' || true)" ]];\
    do sleep 10;\
    done'

helm_check=$(helm ls -A | grep 'gateway-api-controller' || true)

if [ ! -z "$helm_check" ]; then
  echo "Uninstalling Gateway API Controller helm chart..."

  helm delete gateway-api-controller --namespace gateway-api-controller > /dev/null
fi

CLUSTER_SG=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --output json| jq -r '.cluster.resourcesVpcConfig.clusterSecurityGroupId')

IPV4_PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.vpc-lattice\'"].PrefixListId" | jq --raw-output .[])
IPV4_MANAGED_PREFIX=$(aws ec2 get-managed-prefix-list-entries --prefix-list-id $IPV4_PREFIX_LIST_ID --output json  | jq -r '.Entries[0].Cidr')

ipv4_sg_check=$(aws ec2 describe-security-group-rules --filters Name="group-id",Values="$CLUSTER_SG" --query "SecurityGroupRules[?CidrIpv4=='$IPV4_MANAGED_PREFIX'].SecurityGroupRuleId" --output text)

if [ ! -z "$ipv4_sg_check" ]; then
  aws ec2 revoke-security-group-ingress --group-id $CLUSTER_SG --ip-permissions IpProtocol=-1,IpRanges=[{CidrIp=$IPV4_MANAGED_PREFIX}] > /dev/null
fi

IPV6_PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.ipv6.vpc-lattice\'"].PrefixListId" | jq --raw-output .[])
IPV6_MANAGED_PREFIX=$(aws ec2 get-managed-prefix-list-entries --prefix-list-id $IPV6_PREFIX_LIST_ID --output json  | jq -r '.Entries[0].Cidr')

ipv6_sg_check=$(aws ec2 describe-security-group-rules --filters Name="group-id",Values="$CLUSTER_SG" --query "SecurityGroupRules[?CidrIpv6=='$IPV6_MANAGED_PREFIX'].SecurityGroupRuleId" --output text)

if [ ! -z "$ipv6_sg_check" ]; then
  aws ec2 revoke-security-group-ingress --group-id $CLUSTER_SG --ip-permissions IpProtocol=-1,Ipv6Ranges=[{CidrIpv6=$IPV6_MANAGED_PREFIX}] > /dev/null
fi
