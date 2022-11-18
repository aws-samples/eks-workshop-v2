---
title: "Deploy Carts Application on Bottlerocket"
sidebar_position: 54
---

## Deploy carts application pod onto a Bottlerocket node

Lets use Kustomize to change this configuration to deploy the carts application onto the bottlerocket worker nodes:

```bash
$ kubectl apply -k /workspace/modules/security/bottlerocket
```

nodeSelector is the simplest way to constrain Pods to nodes with specific labels, in our case we used a label "role=bottlerocket" on nodes then customize deployment objects through kustomization files suchas deployment.yaml and deployment-db.yaml where we've specified nodeSelector which constrain the cart application and database pods on to bottlerocket nodes:

```kustomization
security/bottlerocket/deployment.yaml
Deployment/carts
```

```kustomization
security/bottlerocket/deployment-db.yaml
Deployment/carts-dynamodb
```

Next, run the following command to confirm the new application is running on the bottlerocket node:

```bash
$ kubectl get pods --selector=app.kubernetes.io/created-by=eks-workshop -n carts -o wide
 ```

Finally, in the Output section, we can view the pods that launched on the bottlerocket node:

```
Node:         ip-10-42-10-115.us-east-1.compute.internal/10.42.10.115
```
