---
title: "Deploy Carts Application on Bottlerocket"
sidebar_position: 50
---

## Deploy nginx pod on a Bottlerocket node

Create a namespace

```bash
$ kubectl create namespace bottlerocket-carts
```

Create a simple cart pod config:

```
cat <<EoF > ~/environment/eks-workshop-v2/bottlerocket-carts.yaml
apiVersion: v1
kind: Pod
metadata:
  name: carts-pod
  namespace: bottlerocket-carts
  labels:
    app.kubernetes.io/created-by: eks-workshop
    app.kubernetes.io/type: app
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    role: bottlerocket
EoF
```

Deploy the application:

```bash
$ kubectl create -f ~/environment/eks-workshop-v2/bottlerocket-carts.yaml
```

Next, run the following command to confirm the new application is running on the bottlerocket node:

```bash
$ kubectl describe pod/nginx -n bottlerocket-nginx
```

Output:

```
Node:         ip-10-42-10-115.us-east-1.compute.internal/10.42.10.115
```

