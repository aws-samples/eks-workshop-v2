---
title: "Associating access policies"
sidebar_position: 13
---

You can assign one or more access policies to access entries of type `STANDARD`. Amazon EKS automatically grants the other types of access entries the permissions required to function properly in your cluster. Amazon EKS access policies include Kubernetes permissions, not IAM permissions. Before associating an access policy to an access entry, make sure that you're familiar with the Kubernetes permissions included in each access policy.

As part of the lab setup we created an IAM role named `eks-workshop-read-only`. In this section we'll provide access to the EKS cluster for this role with a permission set that only allows read-only access.

First lets create the access entry for this IAM role:

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE
```

Now we can associate an access policy for this principal that uses the `AmazonEKSViewPolicy` policy:

```bash wait=30
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=cluster
```

Notice that we have used the `--access-scope` value of `type=cluster`, which gives the principal read-only access to the entire cluster.

Now we can test the access that this role has. First we'll set up a new `kubeconfig` entry that uses the read only IAM role to authenticate with the cluster. This will be mapped to a separate `kubectl` context named `readonly`. You can read more about how this works in the [Kubernetes documentation](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $READ_ONLY_IAM_ROLE --alias readonly --user-alias readonly
```

We can now use `kubectl` commands with the argument `--context readonly` to authenticate with the read-only IAM role. Lets use `kubectl auth whoami` to check this and confirm we'll impersonate the right role:

```bash
$ kubectl --context readonly auth whoami
ATTRIBUTE             VALUE
Username              arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth
UID                   aws-iam-authenticator:1234567890:AKIAIOSFODNN7EXAMPLE
Groups                [system:authenticated]
Extra: accessKeyId    [AKIAIOSFODNN7EXAMPLE]
Extra: arn            [arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth]
Extra: canonicalArn   [arn:aws:iam::1234567890:role/eks-workshop-read-only]
Extra: principalId    [AKIAIOSFODNN7EXAMPLE]
Extra: sessionName    [EKSGetTokenAuth]
```

Now lets try to access pods in the cluster using this IAM role by using :

```bash
$ kubectl --context readonly get pod -A
```

This should return all pods in the cluster. However if we try to perform an action other than reading we should get an error:

```bash expectError=true
$ kubectl --context readonly delete pod -n ui --all
Error from server (Forbidden): pods "ui-7c7948bfc8-wbsbr" is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot delete resource "pods" in API group "" in the namespace "ui"
```

Next we can explore restricting a policy to one or more namespaces. Update the access policy associating for our read-only IAM role using `--access-scope type=namespace`:

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=namespace,namespaces=carts
```

This association explicitly allows access to the `carts` namespace only, replacing the previous cluster-wide association. Lets test this:

```bash
$ kubectl --context readonly get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

But if we try to get pods from all namespaces we will be forbidden:

```bash expectError=true
$ kubectl --context readonly get pod -A
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot list resource "pods" in API group "" at the cluster scope
```

List the associations of the `readonly` role.

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn $READ_ONLY_IAM_ROLE
{
    "associatedAccessPolicies": [
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "carts"
                ]
            },
            "associatedAt": "2024-05-29T17:01:55.233000+00:00",
            "modifiedAt": "2024-05-29T17:02:22.566000+00:00"
        }
    ],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::1234567890:role/eks-workshop-read-only"
}
```

As mentioned, since you used the same `AmazonEKSViewPolicy` policy ARN, it just replaced the previous cluster scoped access configuration to a namespaced scope. Now associate a different policy ARN, scoped to the `ui` namespace.

```bash wait=10
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy \
  --access-scope type=namespace,namespaces=ui
```

Try to run the previous access denied command to delete Pods the `ui` namespace.

```bash
$ kubectl --context readonly delete pod -n ui --all
pod "ui-7c7948bfc8-xdmnv" deleted
```

Now you have access to both namespaces. List the associated access policies.

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn $READ_ONLY_IAM_ROLE
{
    "associatedAccessPolicies": [
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "ui"
                ]
            },
            "associatedAt": "2024-05-29T17:23:55.299000+00:00",
            "modifiedAt": "2024-05-29T17:23:55.299000+00:00"
        },
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "carts"
                ]
            },
            "associatedAt": "2024-05-29T17:01:55.233000+00:00",
            "modifiedAt": "2024-05-29T17:23:28.168000+00:00"
        }
    ],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::1234567890:role/eks-workshop-read-only"
}
```

As you can see it's possible to associate more than one access policy to provide different levels of access.

Check what happens if you list all the Pods in the cluster.

```bash expectError=true
$ kubectl --context readonly get pod -A
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot list resource "pods" in API group "" at the cluster scope
```

Still not have access to the whole cluster, which is expected since the access scope is mapped to the `ui` and `carts` namespaces.

This has demonstrated how we can use associate the pre-defined EKS access policies to access entries in order to easily provide access to an EKS cluster to an IAM role.
