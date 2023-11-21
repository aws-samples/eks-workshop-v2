#!/bin/bash

set -e

echo "Deleting VPC Lattice routes and gateway..."

kubectl delete namespace checkoutv2 --ignore-not-found > /dev/null
kubectl delete namespace checkout --ignore-not-found > /dev/null

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

#echo "Deleting VPC Lattice target groups..."

#tg1=$(aws vpc-lattice list-target-groups --query "items[?name=='k8s-checkout-checkout'].id" --output text)
#
#if [ ! -z "$tg1" ]; then
#  for id in $(aws vpc-lattice list-targets --target-group-identifier $tg1 --query 'items[].id' --output text); do
#    aws vpc-lattice deregister-targets --target-group-identifier $tg1 --targets id=$id,port=8080 > /dev/null
#  done
#
#  aws vpc-lattice delete-target-group --target-group-identifier $tg1 > /dev/null
#fi
#
#tg2=$(aws vpc-lattice list-target-groups --query "items[?name=='k8s-checkout-checkoutv2'].id" --output text)
#
#if [ ! -z "$tg2" ]; then
#  for id in $(aws vpc-lattice list-targets --target-group-identifier $tg2 --query 'items[].id' --output text); do
#    aws vpc-lattice deregister-targets --target-group-identifier $tg2 --targets id=$id,port=8080 > /dev/null
#  done
#
#  aws vpc-lattice delete-target-group --target-group-identifier $tg2 > /dev/null
#fi

PREFIX_LIST_ID=$(aws ec2 describe-managed-prefix-lists --query "PrefixLists[?PrefixListName=="\'com.amazonaws.$AWS_REGION.vpc-lattice\'"].PrefixListId" | jq --raw-output .[])
MANAGED_PREFIX=$(aws ec2 get-managed-prefix-list-entries --prefix-list-id $PREFIX_LIST_ID --output json  | jq -r '.Entries[0].Cidr')
CLUSTER_SG=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --output json| jq -r '.cluster.resourcesVpcConfig.clusterSecurityGroupId')
aws ec2 revoke-security-group-ingress --group-id $CLUSTER_SG --cidr $MANAGED_PREFIX --protocol -1 > /dev/null