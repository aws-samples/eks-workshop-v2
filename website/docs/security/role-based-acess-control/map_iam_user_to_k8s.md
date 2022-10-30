---
title: "Map IAM User to Kubernetes"
sidebar_position: 20
---

Lets define a kubernetes user called carts-user, and map to its IAM user counterpart.

To grant additional AWS users or roles the ability to interact with your cluster, you must update the aws-auth ConfigMap within Kubernetes

Run the following to get the existing ConfigMap and save into a file called aws-auth.yaml:

```bash test=false
$ kubectl get configmap -n kube-system aws-auth -o yaml | grep -v "creationTimestamp\|resourceVersion\|selfLink\|uid" | sed '/^  annotations:/,+2 d' > aws-auth.yaml

```
Some of the values may be dynamically populated when the file is created. To verify everything populated and was created correctly, run the following:

```bash test=false
$ cat aws-auth.yaml

```

Next update 'mapUsers' section of aws-auth.yaml from

```js
data:
  mapUsers: |
    []
```
to

```js
data:
  mapUsers: |
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/carts-user
      username: carts-user

```
make sure that the actual value of ACCOUNT_ID is replaced with ${ACCOUNT_ID}


Next, apply the ConfigMap to apply this mapping to the system:

```bash test=false
$ kubectl apply -f aws-auth.yaml
```