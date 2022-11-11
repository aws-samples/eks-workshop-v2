---
title: "Cleanup"
sidebar_position: 30
weight: 60
---

Delete the sample application

```bash expectError=true
$ kubectl delete -k ./environment/workspace/manifests
```

Delete the node group that was created to test custom networking

```bash expectError=true
$ aws eks delete-nodegroup --region $AWS_DEFAULT_REGION --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking-nodegroup
```

Even after the AWS CLI output says that the cluster is deleted, the delete process might not actually be complete. The delete process takes a few minutes. Confirm that it's complete by running the following command.

```bash expectError=true
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking-nodegroup --query nodegroup.status --output text
```

Delete the node IAM role

Detach the policies from the role.

```bash expectError=true
$ aws iam detach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
$ aws iam detach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
$ aws iam detach-role-policy --role-name $node_role_name --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
```

Delete the role.


```bash expectError=true
$ aws iam delete-role --role-name $node_role_name
```

Reset Amazon VPC CNI configuration

```bash expectError=true
$ kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=false
```

Delete the IAM trust policy JSON file
```bash expectError=true
$ rm node-role-trust-relationship.json
```