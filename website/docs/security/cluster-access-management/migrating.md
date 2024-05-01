---
title: "Migrating an existing aws-auth Identity Mapping to CAM"
sidebar_position: 13
---

## Migrating identities "as-is"

As the last step for this module, you'll go through the migration process from the aws-auth configMap identity mappings to the Cluster Access Management API format. In the last section, you did create a new Access Entry and associated an Access Policy with a cluster wide scope. Now you'll explore how to associate policies scoped by Namespace and how to associate Kubernetes Groups using RBAC permissions to Access Entries.

If you remember, in the existing configuration there is an identity for  EKSDevelopers mapped to a view group in the aws-auth configMap.

```yaml
    - "groups":
      - "view"
      "rolearn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers"
      "username": "developer"
```

```bash
arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers                                                    developer                               view
```

First let's check which kind of access this  view group provides to the EKSDevelopers. Validate the ClusterRoleBinding with that name.

```bash
$ kubectl  get clusterrolebindings view -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: "2024-04-30T19:34:27Z"
  name: view
  resourceVersion: "289126"
  uid: 51b8a3ee-fbce-4598-8f0d-6975fdc98ec1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: view
```

You can see in the roleRef section that it's linked with the view ClusterRole. Take a look on that to see the specific authorization access.

```bash
$ kubectl get clusterrole view -o yaml
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-view: "true"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  creationTimestamp: "2024-04-29T17:37:43Z"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
  name: view
  resourceVersion: "342"
  uid: 197e3581-aa80-4707-be62-9a2be2aaaaa5
rules:
... truncated output
```

This ClusterRole has a long list of apiGroups that can be read by the identity mapped to the view ClusterRoleBinding. You can validate that by impersonating that IAM Role.

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers
Updated context arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:cluster/eks-workshop in /home/ec2-user/.kube/config
```

Test a few commands like the examples below.

```bash
$ kubectl get pods
No resources found in default namespace.
$ kubectl get pods -A
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
assets        assets-7c7948bfc8-qvn2r           1/1     Running   0          25h
carts         carts-6d4478747c-h55kx            1/1     Running   0          25h
carts         carts-dynamodb-d9f9f48b-tkm47     1/1     Running   0          25h
catalog       catalog-76c764cc6d-rfbpr          1/1     Running   0          25h
catalog       catalog-mysql-0                   1/1     Running   0          25h
checkout      checkout-9cc47f6f4-7d847          1/1     Running   0          25h
checkout      checkout-redis-5df64d4f66-h5m6z   1/1     Running   0          25h
kube-system   aws-node-dp6lm                    2/2     Running   0          28h
kube-system   aws-node-lfwr7                    2/2     Running   0          28h
kube-system   aws-node-pgdmv                    2/2     Running   0          28h
kube-system   coredns-5b8cc885bc-d2qzp          1/1     Running   0          28h
kube-system   coredns-5b8cc885bc-rr6sx          1/1     Running   0          28h
kube-system   kube-proxy-2xx74                  1/1     Running   0          28h
kube-system   kube-proxy-l24lx                  1/1     Running   0          28h
kube-system   kube-proxy-vq58f                  1/1     Running   0          28h
orders        orders-5c597c5965-56qkg           1/1     Running   0          25h
orders        orders-mysql-5dcdcccbf9-hst2n     1/1     Running   0          25h
rabbitmq      rabbitmq-0                        1/1     Running   0          25h
ui            ui-68495c748c-bzn92               1/1     Running   0          25h
$ kubectl get clusterrole view -o yaml
Error from server (Forbidden): clusterroles.rbac.authorization.k8s.io "view" is forbidden: User "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/EKSGetTokenAuth" cannot get resource "clusterroles" in API group "rbac.authorization.k8s.io" at the cluster scope
$ kubectl run pause --image public.ecr.aws/eks-distro/kubernetes/pause:3.9
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/EKSGetTokenAuth" cannot create resource "pods" in API group "" in the namespace "default"
```

As you can see, you are able to view Namespaced resources even for all Namespaces, but you're not allowed to view cluster-wide resources, nor create resources.

Create the access entry using the rolearn of the EKSDevelopers identity as the principal-arn in the awscli command, and associate with the existing Kubernetes Group view.

```bash
$ aws eks create-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers --kubernetes-groups view
{
    "accessEntry": {
        "clusterName": "eks-workshop",
        "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers",
        "kubernetesGroups": [
            "view"
        ],
        "accessEntryArn": "arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:access-entry/eks-workshop/role/$AWS_ACCOUNT_ID/EKSDevelopers/d6c7984b-a9e0-60f8-c69f-38e63f8846d6",
        "createdAt": "2024-04-30T19:59:34.955000+00:00",
        "modifiedAt": "2024-04-30T19:59:34.955000+00:00",
        "tags": {},
        "username": "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSDevelopers/{{SessionName}}",
        "type": "STANDARD"
    }
}
```

Check if this Access Entry is associated with any Access Policies.

```bash
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers
{
    "associatedAccessPolicies": [],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers"
}
```

No Access Policies are mapped so far. Go back to the cluster-admin permissions (default IAM Role), and delete the respective identity mapping on the aws-auth configMap using the eksctl cli tool.

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
Updated context arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:cluster/eks-workshop in /home/ec2-user/.kube/config
$ eksctl delete iamidentitymapping --cluster $EKS_CLUSTER_NAME  --arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSPowerUser
2024-04-30 20:02:22 [ℹ]  removing identity "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSPowerUser" from auth ConfigMap (username = "poweruser", groups = ["poweruser"])
$ kubectl -n kube-system get configmap aws-auth -o yaml
apiVersion: v1
data:
  mapAccounts: |
    []
  mapRoles: |
    - groups:
      - system:masters
      rolearn: arn:aws:iam::$AWS_ACCOUNT_ID:role/WSParticipantRole
      username: admin
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::$AWS_ACCOUNT_ID:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-647HpxD4e9mr
  mapUsers: |
    []
kind: ConfigMap
metadata:
  creationTimestamp: "2024-04-29T17:46:45Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "294300"
  uid: 29fc3275-6e5a-4acc-93bc-c31ed4869b7e
```

The entry was removed from the aws-auth configMap. Now, impersonate the EKSDevelopers identity again, and revalidate the access.

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSDevelopers
Updated context arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:cluster/eks-workshop in /home/ec2-user/.kube/config
$ kubectl get pods
No resources found in default namespace.
$ kubectl get pods -A
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
assets        assets-7c7948bfc8-qvn2r           1/1     Running   0          25h
carts         carts-6d4478747c-h55kx            1/1     Running   0          25h
carts         carts-dynamodb-d9f9f48b-tkm47     1/1     Running   0          25h
catalog       catalog-76c764cc6d-rfbpr          1/1     Running   0          25h
catalog       catalog-mysql-0                   1/1     Running   0          25h
checkout      checkout-9cc47f6f4-7d847          1/1     Running   0          25h
checkout      checkout-redis-5df64d4f66-h5m6z   1/1     Running   0          25h
kube-system   aws-node-dp6lm                    2/2     Running   0          28h
kube-system   aws-node-lfwr7                    2/2     Running   0          28h
kube-system   aws-node-pgdmv                    2/2     Running   0          28h
kube-system   coredns-5b8cc885bc-d2qzp          1/1     Running   0          28h
kube-system   coredns-5b8cc885bc-rr6sx          1/1     Running   0          28h
kube-system   kube-proxy-2xx74                  1/1     Running   0          28h
kube-system   kube-proxy-l24lx                  1/1     Running   0          28h
kube-system   kube-proxy-vq58f                  1/1     Running   0          28h
orders        orders-5c597c5965-56qkg           1/1     Running   0          25h
orders        orders-mysql-5dcdcccbf9-hst2n     1/1     Running   0          25h
rabbitmq      rabbitmq-0                        1/1     Running   0          25h
ui            ui-68495c748c-bzn92               1/1     Running   0          25h
$ kubectl get clusterrole view -o yaml
Error from server (Forbidden): clusterroles.rbac.authorization.k8s.io "view" is forbidden: User "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/EKSGetTokenAuth" cannot get resource "clusterroles" in API group "rbac.authorization.k8s.io" at the cluster scope
$ kubectl run pause --image public.ecr.aws/eks-distro/kubernetes/pause:3.9
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/EKSGetTokenAuth" cannot create resource "pods" in API group "" in the namespace "default"
```

The permissions were mapped exactly as they were before. With this you successfully migrated an identity "as-is" from the `aws-auth` configMap to EKS Access Entries!
