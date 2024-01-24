#!/bin/bash

set -e

logmessage "Deleting VPC Lattice routes and gateway..."

kubectl delete namespace checkoutv2 --ignore-not-found

delete-all-if-crd-exists targetgrouppolicies.application-networking.k8s.aws

kubectl delete -f ~/environment/eks-workshop/modules/networking/vpc-lattice/routes --ignore-not-found
cat ~/environment/eks-workshop/modules/networking/vpc-lattice/controller/eks-workshop-gw.yaml | envsubst | kubectl delete --ignore-not-found -f -
kubectl delete -f ~/environment/eks-workshop/modules/networking/vpc-lattice/controller/gatewayclass.yaml --ignore-not-found

logmessage "Waiting for VPC Lattice target groups to be deleted..."

timeout -s TERM 300 bash -c \
    'while [[ ! -z "$(aws vpc-lattice list-target-groups --output text | grep 'checkout' || true)" ]];\
    do sleep 10;\
    done'

helm_check=$(helm ls -A | grep 'gateway-api-controller' || true)

if [ ! -z "$helm_check" ]; then
  logmessage "Uninstalling Gateway API Controller helm chart..."

  helm delete gateway-api-controller --namespace gateway-api-controller
fi

CLUSTER_SG=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --output json| jq -r '.cluster.resourcesVpcConfig.clusterSecurityGroupId')

PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.vpc-lattice\'"].PrefixListId" | jq -r '.[]')
PREFIX_LIST_ID_IPV6=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.ipv6.vpc-lattice\'"].PrefixListId" | jq -r '.[]')

ipv4_sg_check=$(aws ec2 describe-security-group-rules --filters Name="group-id",Values="$CLUSTER_SG" --query "SecurityGroupRules[?PrefixListId=='$PREFIX_LIST_ID'].SecurityGroupRuleId" --output text)

if [ ! -z "$ipv4_sg_check" ]; then
  aws ec2 revoke-security-group-ingress --group-id $CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=${PREFIX_LIST_ID}}],IpProtocol=-1"
fi

ipv6_sg_check=$(aws ec2 describe-security-group-rules --filters Name="group-id",Values="$CLUSTER_SG" --query "SecurityGroupRules[?PrefixListId=='$PREFIX_LIST_ID_IPV6'].SecurityGroupRuleId" --output text)

if [ ! -z "$ipv6_sg_check" ]; then
  aws ec2 revoke-security-group-ingress --group-id $CLUSTER_SG --ip-permissions "PrefixListIds=[{PrefixListId=${PREFIX_LIST_ID_IPV6}}],IpProtocol=-1"
fi

service_network=$(aws vpc-lattice list-service-networks --query "items[?name=="\'$EKS_CLUSTER_NAME\'"].id" | jq -r '.[]')
if [ ! -z "$service_network" ]; then
  association_id=$(aws vpc-lattice list-service-network-vpc-associations --service-network-identifier $service_network --vpc-identifier $VPC_ID --query 'items[].id' | jq -r '.[]')
  if [ ! -z "$association_id" ]; then
    logmessage "Deleting Lattice VPC association..."
    aws vpc-lattice delete-service-network-vpc-association --service-network-vpc-association-identifier $association_id
    sleep 30 # Todo replace with wait
  fi

  logmessage "Deleting Lattice service network..."
  aws vpc-lattice delete-service-network --service-network-identifier $service_network
fi