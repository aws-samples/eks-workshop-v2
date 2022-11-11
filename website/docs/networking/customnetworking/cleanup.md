---
title: "Cleanup"
sidebar_position: 30
weight: 60
---

Delete the sample application

```bash expectError=true
$ kubectl delete -k /workspace/manifests
```

Delete the node group that was created to test custom networking

```bash expectError=true
$ aws eks delete-nodegroup --region $AWS_DEFAULT_REGION --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking-nodegroup
```

Even after the AWS CLI output says that the cluster is deleted, the delete process might not actually be complete. The delete process takes a few minutes. Confirm that it's complete by running the following command.

```bash expectError=true
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name custom-networking-nodegroup --query nodegroup.status --output text
```

Reset Amazon VPC CNI configuration

```bash expectError=true
$ kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=false
```