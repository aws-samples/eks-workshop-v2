---
title: "Introduction"
sidebar_position: 10
---

Run the following command to setup the EKS cluster for this module:

```bash timeout=300 wait=30
$ reset-environment 
```

Currently there are no `Ingress` resources in our cluster, which you can check with the following command:

```bash expectError=true
$ kubectl get ingress -n ui
No resources found
```

There are also no `Service` resources of type `LoadBalancer`, which you can confirm with the following command:

```bash
$ kubectl get svc -n ui
```
