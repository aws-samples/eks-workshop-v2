---
title: "Cluster Admin Access"
sidebar_position: 13
---

## Managing the Cluster Admin access

As explained earlier with the Cluster Access Management API, it is possible to remove the cluster-admin permissions set for the Cluster Creator during the cluster creation time. Let's do that, since the cluster-admin permissions should be used just for troubleshooting purposes or breaking glass situations.

> Remember to replace the principalArn, with the one existing in your cluster.

```bash
$ CLUSTER_CREATOR=$(aws eks list-access-entries --cluster $EKS_CLUSTER_NAME --output text | awk '/CodeBuild/ {print $2}')
$ aws eks delete-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn $CLUSTER_CREATOR
$ aws eks list-access-entries --cluster $EKS_CLUSTER_NAME
{
    "accessEntries": [
        "arn:aws:iam::143095623777:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-wtZ9gonWSMRn"
    ]
}
```

Test your access to the cluster.

```bash
$ kubectl -n kube-system get configmap aws-auth
NAME       DATA   AGE
aws-auth   3      4h28m
$ kubectl get clusterrole cluster-admin
NAME            CREATED AT
cluster-admin   2024-04-29T17:37:43Z
```

You still have cluster-admin access, right? That's because the IAM Role you are using is not the one that created the cluster, this was done by a infrastructure pipeline.

Now, in the `aws-auth` configMap, there is a mapping to your AWS STS Identity, with the `system:masters` group, similar to the one below.

```yaml
- "groups":
    - "system:masters"
  "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1"
  "username": "admin"
```

Check the AWS STS Identity you are using.

```bash
$ aws sts get-caller-identity --query 'Arn'
"arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1/i-06b2ef4cc8104bd8a"
```

That name matches the entry! The only difference is that the entry is mapped to the source AWS IAM Role, other than the AWS STS Identity, so the Arn prefix is a bit different.

So let's go ahead and remove that entry as well.

```bash
$ ROLE_NAME=$(aws sts get-caller-identity --query 'Arn' | cut -d/ -f2)
$ eksctl delete iamidentitymapping --cluster $EKS_CLUSTER_NAME  --arn arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME
2024-04-29 21:50:20 [ℹ]  removing identity "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1" from auth ConfigMap (username = "admin", groups = ["system:masters"])
```

Test your access to the cluster again.

```bash
$ kubectl -n kube-system get configmap aws-auth
error: You must be logged in to the server (Unauthorized)
$ kubectl get clusterrole cluster-admin
error: You must be logged in to the server (Unauthorized)
```

Not authorized, right? This error shows that you're not logged into the cluster. So now you have removed your cluster-admin access to the cluster, and you have no access at all!
If this happened in a cluster set with the `CONFIG_MAP` only authentication mode, and there are none other cluster-admins set, you would have completely lost that access to the cluster, because you can't even list or read the `aws-auth` configMap to add your identity again.

Now with the Cluster Access Management API, it's possible to regain that access with simple `awscli` commands. First get the Arn of your IAM Role.

```bash
$ ROLE_NAME=$(aws sts get-caller-identity --query 'Arn' | cut -d/ -f2)
$ echo $ROLE_NAME
workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1
$ ROLE_ARN=$(aws iam list-roles --query "Roles[?RoleName=='"$ROLE_NAME"'].Arn" --output text)
$ echo $ROLE_ARN
arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1
```

Create the Access Entry.

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn $ROLE_ARN
{
    "accessEntry": {
        "clusterName": "eks-workshop",
        "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1",
        "kubernetesGroups": [],
        "accessEntryArn": "arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:access-entry/eks-workshop/role/$AWS_ACCOUNT_ID/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1/26c79603-ae69-f3ad-a51d-693d6d004af5",
        "createdAt": "2024-04-29T22:43:51.181000+00:00",
        "modifiedAt": "2024-04-29T22:43:51.181000+00:00",
        "tags": {},
        "username": "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1/{{SessionName}}",
        "type": "STANDARD"
    }
}
```

Test your access to the cluster again.

```bash
$ kubectl -n kube-system get configmap aws-auth
Error from server (Forbidden): clusterroles.rbac.authorization.k8s.io is forbidden: User "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1/i-06b2ef4cc8104bd8a" cannot list resource "clusterroles" in API group "rbac.authorization.k8s.io" at the cluster scope
$ kubectl get clusterrole cluster-admin
Error from server (Forbidden): clusterroles.rbac.authorization.k8s.io is forbidden: User "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1/i-06b2ef4cc8104bd8a" cannot list resource "clusterroles" in API group "rbac.authorization.k8s.io" at the cluster scope
```

Still not getting access, but with a different error. That's because the Access Entry was not associated to any Access Policies that was covered in the previous section, so you're just authenticated, but no authorization scope was defined.

Validate that with the command below.

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn $ROLE_ARN
{
    "associatedAccessPolicies": [],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1"
}
```

Now, run the following command to map the newly created Access Entry, to the `AmazonEKSClusterAdminPolicy` Access Policy.

```bash
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME --principal-arn $ROLE_ARN --policy-arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" --access-scope type=cluster
{
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1",
    "associatedAccessPolicy": {
        "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy",
        "accessScope": {
            "type": "cluster",
            "namespaces": []
        },
        "associatedAt": "2024-04-29T22:50:22.564000+00:00",
        "modifiedAt": "2024-04-29T22:50:22.564000+00:00"
    }
}
```

Notice the policyArn and accessScope values. Validate the policy association again.

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn $ROLE_ARN
{
    "associatedAccessPolicies": [
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy",
            "accessScope": {
                "type": "cluster",
                "namespaces": []
            },
            "associatedAt": "2024-04-29T22:50:22.564000+00:00",
            "modifiedAt": "2024-04-29T22:50:22.564000+00:00"
        }
    ],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/workshop-stack-Cloud9Stack-1UEGQA-EksWorkshopC9Role-0GSFxRAwfFG1"
}
```

Test your access to the cluster one more time.

```bash
$ kubectl -n kube-system get configmap aws-auth
NAME       DATA   AGE
aws-auth   3      5h8m
$ kubectl get clusterrole cluster-admin
NAME            CREATED AT
cluster-admin   2024-04-29T17:37:43Z
```

You now have regain cluster-admin access to the cluster! **Use it with responsibility!**
