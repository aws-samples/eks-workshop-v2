#!/bin/bash

betaendpoint=$1
environment=$2


set -Eeuo pipefail

if [ -z "$environment" ]; then
  export EKS_CLUSTER_NAME="eks-workshop"
else
  export EKS_CLUSTER_NAME="eks-workshop-${environment}"
fi

if [ -z "$betaendpoint" ]; then
  echo "Please provide a non empty value for beta endpoint."
  exit -1
fi

AWS_REGION=${AWS_REGION:-""}

if [ -z "$AWS_REGION" ]; then
  echo "Warning: Defaulting region to us-west-2"

  export AWS_REGION="us-west-2"
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

root="$SCRIPT_DIR/.."

#cat $root/cluster/eksctl/cluster.yaml | envsubst | eksctl create cluster -f -

CFN_STACK_RESP=$(aws cloudformation describe-stacks)
CFN_STACK_ID=$(echo ${CFN_STACK_RESP} | jq -r '.Stacks[] | select (.StackName == "eks-workshop-vpc" ) | .StackId')

if [ -z "${CFN_STACK_ID}" ]
then
  CFN_STACK_ID=$(aws cloudformation create-stack --stack-name eks-workshop-vpc \
    --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-ipv6-vpc-public-private-subnets.yaml \
    --parameters file://vpc-cfn-params.json | jq -r '.StackId')
  aws cloudformation wait stack-create-complete --stack-name ${CFN_STACK_ID}
  CFN_STACK_RESP=$(aws cloudformation describe-stacks --stack-name eks-workshop-vpc)
else 
  echo "Cloudformation stack eks-workshop-vpc already created : ${CFN_STACK_ID}"
fi

PRIVATE_SUBNETS=$(echo ${CFN_STACK_RESP} | jq -r '.Stacks[] | select (.StackName == "eks-workshop-vpc" ) | .Outputs[] | select(.OutputKey=="SubnetsPrivate") | .OutputValue')
PRIVATE_SUBNETS=( ${PRIVATE_SUBNETS//,/ } )
PUBLIC_SUBNETS=$(echo ${CFN_STACK_RESP} | jq -r '.Stacks[] | select (.StackName == "eks-workshop-vpc" ) | .Outputs[] | select(.OutputKey=="SubnetsPublic") | .OutputValue')
PUBLIC_SUBNETS=( ${PUBLIC_SUBNETS//,/ } )
echo ${PRIVATE_SUBNETS[0]} and ${PRIVATE_SUBNETS[1]}
echo ${PUBLIC_SUBNETS[0]} and ${PUBLIC_SUBNETS[1]}

ROLES=$(aws iam list-roles --path-prefix /eksworkshop/)
EKS_ROLE=$(echo ${ROLES} | jq -r '.Roles[] | select(.RoleName == "clusterRole") | .Arn')
if [ -z "${EKS_ROLE}" ]
then
  echo "Creating a IAM ROLE: /eksworkshop/clusterRole"
  EKS_ROLE=$(aws iam create-role --role-name clusterRole --path /eksworkshop/ --assume-role-policy-document file://"cluster-trust-policy.json" | jq -r '.role.Arn')
  aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --role-name clusterRole
else
  echo "EKS IAM role already created: ${EKS_ROLE}"
fi

CLUSTER_NAME=$(aws eks list-clusters --endpoint ${betaenpoint} | jq -r '. | select( .clusters[] | contains("eks-workshop") ) | .clusters[]')

if [ -z "${CLUSTER_NAME}" ]
then
  aws eks create-cluster --name ${EKS_CLUSTER_NAME} --kubernetes-version 1.25 --role-arn $EKS_ROLE \
   --resources-vpc-config subnetIds=${PRIVATE_SUBNETS[0]},${PRIVATE_SUBNETS[1]} --region us-west-2 \
   --endpoint ${betaenpoint}
  aws eks wait cluster-active --name ${EKS_CLUSTER_NAME} --endpoint ${betaenpoint}
else 
  echo "Cluster already created: ${CLUSTER_NAME}"
fi

EKS_NG_ROLE=$(echo ${ROLES} | jq -r '.Roles[] | select(.RoleName == "eksNodeRole") | .Arn')
if [ -z "${EKS_NG_ROLE}" ]
then
  echo "Creating a IAM ROLE: /eksworkshop/eksNodeRole"
  EKS_NG_ROLE=$(aws iam create-role --role-name eksNodeRole --path /eksworkshop/ --assume-role-policy-document file://"nodegroup-trust-policy.json" | jq -r '.role.Arn')
  aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --role-name eksNodeRole
  aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly --role-name eksNodeRole
  echo "Created a IAM ROLE: /eksworkshop/eksNodeRole" 
else
  echo "EKS IAM role already created: ${EKS_NG_ROLE}"
fi

NODEGROUP_NAME=$(aws eks list-nodegroups --cluster-name ${EKS_CLUSTER_NAME} --endpoint ${betaenpoint} | jq -r '. | select( .nodegroups[] | contains("default") ) | .nodegroups[]')
if [ -z "${NODEGROUP_NAME}" ]
then
  aws eks create-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name default --subnets ${PRIVATE_SUBNETS[0]} ${PUBLIC_SUBNETS[0]} ${PRIVATE_SUBNETS[1]} ${PUBLIC_SUBNETS[1]}  --node-role ${EKS_NG_ROLE} --endpoint ${betaenpoint} --scaling-config minSize=0,maxSize=10,desiredSize=2
  aws eks wait nodegroup-active --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name default --endpoint ${betaenpoint}
else 
  echo "Nodegroup is already created: ${NODEGROUP_NAME}"
fi


