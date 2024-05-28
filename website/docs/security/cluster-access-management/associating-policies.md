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

```bash
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
Username              arn:aws:sts::123456789012:assumed-role/eks-workshop-read-only/EKSGetTokenAuth
UID                   aws-iam-authenticator:123456789012:AKIAIOSFODNN7EXAMPLE
Groups                [system:authenticated]
Extra: accessKeyId    [AKIAIOSFODNN7EXAMPLE]
Extra: arn            [arn:aws:sts::123456789012:assumed-role/eks-workshop-read-only/EKSGetTokenAuth]
Extra: canonicalArn   [arn:aws:iam::123456789012:role/eks-workshop-read-only]
Extra: principalId    [AKIAIOSFODNN7EXAMPLE]
Extra: sessionName    [EKSGetTokenAuth]
```

Now lets try to access pods in the cluster using this IAM role by using :

```bash
$ kubectl --context readonly get pod -A
```

This should return all pods in the cluster. However if we try to perform an action other than reading we should get an error:

```bash expectError=true
$ kubectl --context readonly delete pod -n assets --all
Error from server (Forbidden): pods "assets-7c7948bfc8-wbsbr" is forbidden: User "arn:aws:sts::123456789012:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot delete resource "pods" in API group "" in the namespace "assets"
```

Next we can explore restricting a policy to one or more namespaces. Update the access policy associating for our read-only IAM role using `--access-scope type=namespace`:

```bash
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $READ_ONLY_IAM_ROLE \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy \
  --access-scope type=namespace,namespaces=carts
```

This association explicitly allows access to the `carts` namespace. Lets test this:

```bash
$ kubectl --context readonly get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-vvzhm          1/1     Running   0          5m54s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

But if we try to get pods from all namespaces we will be forbidden:

```bash expectError=true
$ kubectl --context readonly get pod -A
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::123456789012:assumed-role/eks-workshop-read-only/EKSGetTokenAuth" cannot list resource "pods" in API group "" at the cluster scope
```

This has demonstrated how we can use associate the pre-defined EKS access policies to access entries in order to easily provide access to an EKS cluster to an IAM role.
