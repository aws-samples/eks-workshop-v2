#!/bin/bash

if [[ -v C9_USER ]]; then
    
    
    echo 'Deleting ClusterRole config'
    kubectl delete ClusterRoleBinding/eks-console-dashboard-full-access-binding --ignore-not-found=true > /dev/null
    kubectl wait --for=delete ClusterRoleBinding/eks-console-dashboard-full-access-binding --timeout=60s > /dev/null

    kubectl delete ClusterRole/eks-console-dashboard-full-access-clusterrole --ignore-not-found=true > /dev/null
    kubectl wait --for=delete ClusterRole/eks-console-dashboard-full-access-clusterrole --timeout=60s > /dev/null

    echo "Deleting IAM user/role from RBAC auth-config2"
    ACCOUNTID=$(aws sts get-caller-identity | jq -r .Account)    

    echo "Removing arn:aws:iam::**:role/${C9_USER} from RBAC"
    eksctl delete iamidentitymapping --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --arn arn:aws:iam::${ACCOUNTID}:role/${C9_USER} -d > /dev/null  2>&1

    echo "Removing arn:aws:iam::**:user/${C9_USER} from RBAC"
    eksctl delete iamidentitymapping --cluster ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --arn arn:aws:iam::${ACCOUNTID}:user/${C9_USER} -d > /dev/null  2>&1
else
   echo "No env C9_USER.. Nothing to delete "
fi
