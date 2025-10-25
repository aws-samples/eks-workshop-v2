---
title: "Integrating with Kubernetes RBAC"
sidebar_position: 14
---

As previously mentioned, the cluster access management controls and associated APIs don't replace the existing RBAC authorizer in Amazon EKS. Rather, Amazon EKS access entries can be combined with the RBAC authorizer to grant cluster access to an AWS IAM principal while relying on Kubernetes RBAC to apply desired permissions.

In this section of the lab, we'll show how to configure access entries with granular permissions using Kubernetes groups. This is useful when the pre-defined access policies are too permissive. As part of the lab setup, we created an IAM role named `eks-workshop-carts-team`. In this scenario, we'll demonstrate how to use that role to provide a team that only works on the **carts** service with permissions that allow them to view all resources in the `carts` namespace, but also delete pods.

First, let's create the Kubernetes objects that model our required permissions. This Role provides the permissions we outlined above:

::yaml{file="manifests/modules/security/cam/rbac/role.yaml" paths="metadata.namespace,rules.0,rules.1"}

1. Restrict the Role permissions to apply only to the `carts` namespace
2. This rule allows read-only operations `verbs: ["get", "list", "watch"]` on all resources `resources: ["*"]`
3. This rule allows delete operations `verbs: ["delete"]` specific to pods only `resources: ["pods"]`

And this `RoleBinding` will map the Role to a Group named `carts-team`:

::yaml{file="manifests/modules/security/cam/rbac/rolebinding.yaml" paths="roleRef,subjects.0"}

1. `roleRef` references the `carts-team-role` Role we created earlier 
2. `subjects` specifies that a Group named `carts-team` will get the permissions associated with the Role

Let's apply these manifests:

```bash
$ kubectl --context default apply -k ~/environment/eks-workshop/modules/security/cam/rbac
```

Now let's create the access entry which maps the carts team's IAM role to the `carts-team` Kubernetes RBAC group:

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME \
  --principal-arn $CARTS_TEAM_IAM_ROLE \
  --kubernetes-groups carts-team
```

Now we can test the access that this role has. Let's set up a new `kubeconfig` entry that uses the carts team's IAM role to authenticate with the cluster with the context `carts-team`:

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME \
  --role-arn $CARTS_TEAM_IAM_ROLE --alias carts-team --user-alias carts-team
```

Now let's try to access pods in the `carts` namespace using the carts team's IAM role by using `--context carts-team`:

```bash
$ kubectl --context carts-team get pod -n carts
NAME                            READY   STATUS    RESTARTS   AGE
carts-6d4478747c-hp7x8          1/1     Running   0          3m27s
carts-dynamodb-d9f9f48b-k5v99   1/1     Running   0          15d
```

We should also be able to delete pods in the namespace:

```bash
$ kubectl --context carts-team delete pod --all -n carts
pod "carts-6d4478747c-hp7x8" deleted
pod "carts-dynamodb-d9f9f48b-k5v99" deleted
```

However, if we try to delete another resource like a `Deployment`, we will be forbidden:

```bash expectError=true
$ kubectl --context carts-team delete deployment --all -n carts
Error from server (Forbidden): deployments.apps is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-team/EKSGetTokenAuth" cannot list resource "deployments" in API group "apps" in the namespace "carts"
```

And if we try to access pods in a different namespace, it will also be forbidden:

```bash expectError=true
$ kubectl --context carts-team get pod -n catalog
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-team/EKSGetTokenAuth" cannot list resource "pods" in API group "" in the namespace "catalog"
```

This has demonstrated how we can associate Kubernetes RBAC groups to access entries in order to provide fine-grained permissions to an EKS cluster for an IAM role.
