---
title: "Managing cluster access"
sidebar_position: 12
---

Now that you have a basic understanding of Cluster Access Management API, let's start with some hands-on activities. First, it's important to know that before the Cluster Access Management API was available, Amazon EKS relied on the `aws-auth` ConfigMap to authenticate and provide access to clusters. Amazon EKS now provides three different authentication modes:

1. `CONFIG_MAP`: Uses `aws-auth` ConfigMap exclusively (this will be deprecated in the future)
2. `API_AND_CONFIG_MAP`: Sources authenticated IAM principals from both EKS access entry APIs and the `aws-auth` ConfigMap, prioritizing the access entries
3. `API`: Exclusively relies on EKS access entry APIs (recommended method)

:::note
You can update your cluster configuration from `CONFIG_MAP` to `API_AND_CONFIG_MAP` and from `API_AND_CONFIG_MAP` to `API`, but not the other way around. This is a one-way operation - once you move toward using the Cluster Access Management API, you won't be able to revert to relying solely on the `aws-auth` ConfigMap authentication.
:::

Let's check which authentication method your cluster is configured with using `awscli`:

```bash
$ aws eks describe-cluster --name $EKS_CLUSTER_NAME --query 'cluster.accessConfig'
{
  "authenticationMode": "API_AND_CONFIG_MAP"
}
```

Since the cluster is already using the API as one of the authentication options, EKS has already mapped a couple of default access entries to the cluster. Let's check them:

```bash
$ aws eks list-access-entries --cluster $EKS_CLUSTER_NAME
{
    "accessEntries": [
        "arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr",
        "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-TesterCodeBuildRoleC9232875-RyhCKIXckZri"
    ]
}
```

These access entries are automatically created when the authentication mode is set to `API_AND_CONFIG_MAP` or `API` to grant access for the cluster creator entity and the Managed Node Groups that belong to the cluster.

The cluster creator is the entity that actually created the cluster, either via AWS Console, `awscli`, eksctl or any Infrastructure-as-Code (IaC) tool such as AWS CloudFormation or Terraform. This identity is automatically mapped to the cluster at creation time and was not visible in the past when the authentication method was restricted to `CONFIG_MAP`. Now, with the Cluster Access Management API, it's possible to opt-out of creating this identity mapping or even remove it after the cluster is deployed.

Let's describe these access entries to see more information:

```bash
$ NODE_ROLE=$(aws eks list-access-entries --cluster $EKS_CLUSTER_NAME --output text | awk '/NodeInstanceRole/ {print $2}')
$ aws eks describe-access-entry --cluster $EKS_CLUSTER_NAME --principal-arn $NODE_ROLE
{
    "accessEntry": {
        "clusterName": "eks-workshop",
        "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr",
        "kubernetesGroups": [
            "system:nodes"
        ],
        "accessEntryArn": "arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:access-entry/eks-workshop/role/$AWS_ACCOUNT_ID/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr/dcc7957b-b333-5c6b-f487-f7538085d799",
        "createdAt": "2024-04-29T17:46:47.836000+00:00",
        "modifiedAt": "2024-04-29T17:46:47.836000+00:00",
        "tags": {},
        "username": "system:node:{{EC2PrivateDNSName}}",
        "type": "EC2_LINUX"
    }
}
```
