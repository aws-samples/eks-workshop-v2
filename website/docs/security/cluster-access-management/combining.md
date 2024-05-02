---
title: "Combining Access Policies with Kubernetes Groups"
sidebar_position: 14
---

## Granting granular access level with EKS Access Policies and RBAC

Even with the successful migration of the identity, it still relies on managing Kubernetes resources, so access to the cluster is required for that. You may noticed that you created the access entry for the EKSDevelopers without interacting with the Kubernetes API, just issuing an `awscli` command. With that said, maybe there are a few questions:
How can you simplify the access management?
How to provide a more granular access to the EKSDevelopers entity?

Let's dive deep on that. As we validated, there were no Access Policies linked to the EKSDevelopers Access Entry, and as yu saw in the first part of this module, there is already an Access Policy with view permissions.

Without changing back to the cluster-admin permissions on `kubeconfig`, update the EKSDevelopers Access Entry, to use the AmazonEKSViewPolicy Access Policy, and remove the Kubernetes Group associated earlier.

```bash
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy --access-scope type=cluster
{
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly",
    "associatedAccessPolicy": {
        "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
        "accessScope": {
            "type": "cluster",
            "namespaces": []
        },
        "associatedAt": "2024-04-30T22:51:05.514000+00:00",
        "modifiedAt": "2024-04-30T22:51:05.514000+00:00"
    }
}
$ aws eks update-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly
{
    "accessEntry": {
        "clusterName": "eks-workshop",
        "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly",
        "kubernetesGroups": [],
        "accessEntryArn": "arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:access-entry/eks-workshop/role/$AWS_ACCOUNT_ID/EKSViewOnly/aec7982d-425b-3e2d-7c4e-92e091865fbc",
        "createdAt": "2024-04-30T18:53:09.753000+00:00",
        "modifiedAt": "2024-04-30T22:52:50.639000+00:00",
        "tags": {},
        "username": "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/{{SessionName}}",
        "type": "STANDARD"
    }
}
```

The output of the commands showed that now the AmazonEKSViewPolicy is associated with the EKSDevelopers Access Entry, and no Kubernetes Groups are associated anymore. Go ahead and test your access again.

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

Exactly the same permissions, right?
What about granting a more granular access, and provide an edit permission to the EKSDevelopers using a Kubernetes Group. There is a RoleBinding called developers previously created in the `default` Namespace.

Run the command below to update the EKSDevelopers Access Entry and associate it with the developers group.

```bash
$ aws eks update-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly --kubernetes-groups developers
{
    "accessEntry": {
        "clusterName": "eks-workshop",
        "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly",
        "kubernetesGroups": [
            "developers"
        ],
        "accessEntryArn": "arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:access-entry/eks-workshop/role/$AWS_ACCOUNT_ID/EKSViewOnly/aec7982d-425b-3e2d-7c4e-92e091865fbc",
        "createdAt": "2024-04-30T18:53:09.753000+00:00",
        "modifiedAt": "2024-04-30T23:01:15.486000+00:00",
        "tags": {},
        "username": "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/{{SessionName}}",
        "type": "STANDARD"
    }
}
```

Now you have an Access Policy with view access to the cluster, and an edit policy using a Kubernetes Group mapping.
One more time, check your access.

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
pod/pause created
```

You can see that you can now create resources on the `default` Namespace. Try to delete the newly created Pod, and create that in the `ui` Namespace.

```bash
$ kubectl delete pod pause
pod "pause" deleted
WSParticipantRole:/eks-workshop $ kubectl -n ui run pause --image public.ecr.aws/eks-distro/kubernetes/pause:3.9
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/EKSGetTokenAuth" cannot create resource "pods" in API group "" in the namespace "ui"
```

The creation was forbidden because the RoleBinding is restricted to the `default` Namespace. Go back to the cluster-admin permissions to check that, since edit access level, don't allow you to view authentication and authorization related resources.

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
Updated context arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:cluster/eks-workshop in /home/ec2-user/.kube/config
$ kubectl get rolebinding developers -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: "2024-04-30T22:57:53Z"
  name: developers
  namespace: default
  resourceVersion: "326860"
  uid: 2ecd8502-0d5c-482b-ba54-8621fab36b70
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: developers
```

Now, since this is a simple edit policy, it is basically the same as the AmazonEKSEditPolicy, Access Policy. Let's try then to achieve the same permissions level using just those.

Remove the Kubernetes Group associated with the EKSDevelopers Access Entry.

```bash
$ aws eks update-access-entry --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly
{
    "accessEntry": {
        "clusterName": "eks-workshop",
        "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly",
        "kubernetesGroups": [],
        "accessEntryArn": "arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:access-entry/eks-workshop/role/$AWS_ACCOUNT_ID/EKSViewOnly/aec7982d-425b-3e2d-7c4e-92e091865fbc",
        "createdAt": "2024-04-30T18:53:09.753000+00:00",
        "modifiedAt": "2024-04-30T23:12:45.118000+00:00",
        "tags": {},
        "username": "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/{{SessionName}}",
        "type": "STANDARD"
    }
}
```

Create another association with this Access Entry, now using the AmazonEKSEditPolicy, scoped to the `default` Namespace.

```bash
$ aws eks associate-access-policy --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy --access-scope type=namespace,namespaces=default
{
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly",
    "associatedAccessPolicy": {
        "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy",
        "accessScope": {
            "type": "namespace",
            "namespaces": [
                "default"
            ]
        },
        "associatedAt": "2024-04-30T23:17:03.194000+00:00",
        "modifiedAt": "2024-04-30T23:17:03.194000+00:00"
    }
}
$ aws eks list-associated-access-policies --cluster-name $EKS_CLUSTER_NAME --principal-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly
{
    "associatedAccessPolicies": [
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy",
            "accessScope": {
                "type": "namespace",
                "namespaces": [
                    "default"
                ]
            },
            "associatedAt": "2024-04-30T23:17:03.194000+00:00",
            "modifiedAt": "2024-04-30T23:17:03.194000+00:00"
        },
        {
            "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
            "accessScope": {
                "type": "cluster",
                "namespaces": []
            },
            "associatedAt": "2024-04-30T22:51:05.514000+00:00",
            "modifiedAt": "2024-04-30T22:51:05.514000+00:00"
        }
    ],
    "clusterName": "eks-workshop",
    "principalArn": "arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly"
}
```

Impersonated the EKSDevelopers Role one last time, and test your access.

```bash
$ aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/EKSViewOnly
Updated context arn:aws:eks:us-west-2:$AWS_ACCOUNT_ID:cluster/eks-workshop in /home/ec2-user/.kube/config
$ kubectl get pods
No resources found in default namespace.
$ kubectl get pods -A
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
assets        assets-7c7948bfc8-qvn2r           1/1     Running   0          26h
carts         carts-6d4478747c-h55kx            1/1     Running   0          26h
carts         carts-dynamodb-d9f9f48b-tkm47     1/1     Running   0          26h
catalog       catalog-76c764cc6d-rfbpr          1/1     Running   0          26h
catalog       catalog-mysql-0                   1/1     Running   0          26h
checkout      checkout-9cc47f6f4-7d847          1/1     Running   0          26h
checkout      checkout-redis-5df64d4f66-h5m6z   1/1     Running   0          26h
kube-system   aws-node-dp6lm                    2/2     Running   0          29h
kube-system   aws-node-lfwr7                    2/2     Running   0          29h
kube-system   aws-node-pgdmv                    2/2     Running   0          29h
kube-system   coredns-5b8cc885bc-d2qzp          1/1     Running   0          29h
kube-system   coredns-5b8cc885bc-rr6sx          1/1     Running   0          29h
kube-system   kube-proxy-2xx74                  1/1     Running   0          29h
kube-system   kube-proxy-l24lx                  1/1     Running   0          29h
kube-system   kube-proxy-vq58f                  1/1     Running   0          29h
orders        orders-5c597c5965-56qkg           1/1     Running   0          26h
orders        orders-mysql-5dcdcccbf9-hst2n     1/1     Running   0          26h
rabbitmq      rabbitmq-0                        1/1     Running   0          26h
ui            ui-68495c748c-bzn92               1/1     Running   0          26h
$ kubectl get clusterroles
Error from server (Forbidden): clusterroles.rbac.authorization.k8s.io is forbidden: User "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/EKSGetTokenAuth" cannot list resource "clusterroles" in API group "rbac.authorization.k8s.io" at the cluster scope
$ kubectl run pause --image public.ecr.aws/eks-distro/kubernetes/pause:3.9
pod/pause created
$ kubectl delete pod pause
pod "pause" deleted
$ kubectl -n ui run pause --image public.ecr.aws/eks-distro/kubernetes/pause:3.9
Error from server (Forbidden): pods is forbidden: User "arn:aws:sts::$AWS_ACCOUNT_ID:assumed-role/EKSViewOnly/EKSGetTokenAuth" cannot create resource "pods" in API group "" in the namespace "ui"
```

You have achieved the same granular permissions using just the Cluster Access Management API!

In conclusion, the Cluster Access Management API, facilitates the Authentication and Authorization management with Amazon EKS Cluster without the need to interact with the Kubernetes API. You can also mix and match Access Policies with RBAC and Kubernetes Groups to achieve a more granular level of permissions if you need custom RBACs and scopes that are not covered so far in the EKS Access Policies.
