---
title: "Migrating from aws-auth identity mapping"
sidebar_position: 20
---

Customer who already use EKS may already be using the `aws-auth` ConfigMap mechanism to manage IAM principal access to cluster. This section demonstrates how you can migrate entries from this older mechanism to using cluster access entries.

An IAM role `eks-workshop-admins` has been pre-configured in the EKS cluster that is used for a group with EKS administrative permissions. Lets check the `aws-auth` ConfigMap:

```bash
$ kubectl --context default get -o yaml -n kube-system cm aws-auth
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::1234567890:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-acgt4WAVfXAA
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:masters
      rolearn: arn:aws:iam::1234567890:role/eks-workshop-admins
      username: cluster-admin
  mapUsers: |
    []
kind: ConfigMap
metadata:
  creationTimestamp: "2024-05-09T15:21:57Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "5186190"
  uid: 2a1f9dc7-e32d-44e5-93b3-e5cf7790d95e
```

Impersonate this IAM role to check its access:

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $ADMINS_IAM_ROLE --alias admins --user-alias admins
```

We should be able to list any pods, for example:

```bash
$ kubectl --context admins get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

Delete the `aws-auth` ConfigMap entry for this IAM role, we'll use `eksctl` for convenience:

```bash wait=10
$ eksctl delete iamidentitymapping --cluster $EKS_CLUSTER_NAME --arn $ADMINS_IAM_ROLE
```

Now if we try the same command as before we will be denied access:

```bash expectError=true
$ kubectl --context admins get pod -n carts
error: You must be logged in to the server (Unauthorized)
```

Lets add an access entry to enable the cluster admins to access the cluster again:

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $ADMINS_IAM_ROLE
```

Now we can associate an access policy for this principal that uses the `AmazonEKSClusterAdminPolicy` policy:

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $ADMINS_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

Test access has working again:

```bash
$ kubectl --context admins get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```
