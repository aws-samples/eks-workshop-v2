---
title: "Introduction"
sidebar_position: 10
---

:::info AWS Load Balancer Controller
The AWS Load Balancer Controller is included with Amazon EKS Auto Mode and runs in the control plane. It will automatically provision AWS load balancers when you create Ingress resources.
:::

Currently there are no Ingress resources in our cluster, which you can check with the following command:

```bash expectError=true
$ kubectl get ingress -n ui
No resources found in ui namespace.
```

There are also no Service resources of type `LoadBalancer`, which you can confirm with the following command:

```bash
$ kubectl get svc -n ui
NAME   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   10.100.221.103   <none>        80/TCP    29m
```
