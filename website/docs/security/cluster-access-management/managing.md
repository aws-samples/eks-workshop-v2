---
title: "Managing Cluster Access"
sidebar_position: 12
---

## Authentication modes, identity mappings, and access entries

Now that you have a basic understanding of Cluster Access Management API, let's start some hands on activities. But first it's important to know that before the Cluster Access Management API was available, Amazon EKS relied on the aws-auth configMap to authenticate and provide access to the clusters. With that said, Amazon EKS provide three different modes of authentication

1. CONFIG_MAP: Uses aws-auth configMap exclusively. (this will be deprecated at some point)
2. API_AND_CONFIG_MAP Source authenticated IAM principals from both EKS Access Entry APIs and the aws-auth configMap, prioritizing the Access Entries. Ideal to migrate existing aws-auth permissions to Access Entries.
3. API Exclusively rely on EKS Access Entry APIs.This is recommended method.

Check which method your cluster is configured with `awscli`.

```bash
$ aws eks describe-cluster —name $EKS_CLUSTER_NAME --query 'cluster.accessConfig'
{
  "authenticationMode": "API_AND_CONFIG_MAP"
}
```

As you can see the cluster is set to use both API_AND_CONFIG_MAP for authentication. Let's then take a look on the existing identities that are authorized to access the cluster checking the aws-auth configMap.

```bash
$ kubectl -n kube-system get configmap aws-auth -o yaml
apiVersion: v1
data:
  mapAccounts: |
    []
  mapRoles: |
    - "groups":
      - "view"
      "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers"
      "username": "developer"
    - "groups":
      - "system:bootstrappers"
      - "system:nodes"
      "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr"
      "username": "system:node:{{EC2PrivateDNSName}}"
    - "groups":
      - "system:masters"
      "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/WSParticipantRole"
      "username": "admin"
    - "groups":
      - "system:masters"
      "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1"
      "username": "admin"
  mapUsers: |
    []
kind: ConfigMap
metadata:
  creationTimestamp: "2024-04-29T17:46:45Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "39871"
  uid: 29fc3275-6e5a-4acc-93bc-c31ed4869b7e
```

Another way to check the identities authorized to access the cluster is to use the eksctl tool, using the below command.

```bash
$ eksctl get iamidentitymapping --cluster $EKS_CLUSTER_NAME
ARN                                                                                             USERNAME                                GROUPS                                  ACCOUNT
arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers                                                    developer                               view
arn:aws:iam::$AWS_ACCOUNT_ID:role/WSParticipantRole                                                admin                                   system:masters
arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr system:node:{{EC2PrivateDNSName}}       system:bootstrappers,system:nodes
arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1 admin                                   system:masters
```

As you could see there are a few identities allowed to access the cluster, each one with a specific access scope, let's dive deep on each one of those, since we'll use this information to translated the existing setup using the aws-auth configMap, to EKS Access Entries.

Notice that on the aws-auth configMap, each array under the mapRoles section, starts with groups, which translates to a list of Kubernetes groups or the Kubernetes Roles and ClusterRoles. Each group, is mapped to an AWS IAM Role, and an abstract username. Let's see a couple of examples.

```bash
$ kubectl get clusterrolebindings | grep -e ^admin -e ^view
admin                    2024-04-29T17:37:43Z
view                     2024-04-29T17:37:43Z
```

Here, the `group` developers is basically a Kubernetes group defined in ClusterRoleBindings, and the Role after `rolearn`. is the IAM Role that's mapped to those groups.

```yaml
- "groups":
    - "view"
  "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers"
  "username": "developer"
```

```
arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers                                                    developer                               view
```

In the next example, the groups are `system:bootstrappers` and `system:nodes`git , which is mapped to the IAM Role assigned to the Managed Node Group Instance Profile.

```yaml
- "groups":
    - "system:bootstrappers"
    - "system:nodes"
  "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr"
  "username": "system:node:{{EC2PrivateDNSName}}"
```

```
arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr system:node:{{EC2PrivateDNSName}}       system:bootstrappers,system:nodes
```

The last example has the map to the system:masters group, which is basically the cluster-admin.

```yaml
- "groups":
    - "system:masters"
  "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/WSParticipantRole"
  "username": "admin"
- "groups":
    - "system:masters"
  "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1"
  "username": "admin"
```

```
arn:aws:iam::$AWS_ACCOUNT_ID:role/WSParticipantRole                                                admin                                   system:masters
arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr system:node:{{EC2PrivateDNSName}}       system:bootstrappers,system:nodes
```

```bash
$ kubectl get clusterrolebindings cluster-admin -o yaml | yq .subjects
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:masters
```

Since the cluster is already using the API as one of the authentication options, EKS already mapped a couple of default Access Entries to the cluster. Let's check them.

```bash
$ aws eks list-access-entries --cluster $EKS_CLUSTER_NAME
{
    "accessEntries": [
        "arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr",
        "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-TesterCodeBuildRoleC9232875-RyhCKIXckZri"
    ]
}
```

These Access Entries, are automatically created at the moment the authenticationMode is set to API_AND_CONFIG_MAP or API, to grant access for the Cluster Creator entity and the Managed Node Groups that belongs to the cluster.

The Cluster Creator, belongs to the entity that actually created the cluster, either via AWS Console, `awscli`, eksctl or any Infrastructure-as-Code (IaC) such as AWS Cloud Formation or Terraform. The identity is automatically mapped to the cluster at the creation time, and it was not visible in the past, when the authentication method was restricted to CONFIG_MAP. Now, with the Cluster Access Management API, it is possible to opt-out to create this identity mapping or even remove it after the cluster is deployed.

If you describe these Access Entries, you'll be able to see a similar mapping shown on the previous examples using the aws-auth configMap. Let's see the one mapped to the Managed Node Group.

> Remember to replace the principalArn, with the one existing in your cluster.

```bash
$ aws eks describe-access-entry --cluster $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr
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

Notice the kubernetesGroups, principalArn, and username that are the same values you saw on the configMap example.

Go ahead and try to describe the other Access Entry, that belongs to the Cluster Creator, and doesn't exist on the configMap.
