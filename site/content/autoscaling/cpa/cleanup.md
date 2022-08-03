---
title: "Clean Up"
date: 2022-08-01T00:00:00-03:00
weight: 4
---

### Cleaning up

**To delete cluster proportional autoscaler from the EKS cluster**

```bash
kubectl delete deployment dns-autoscaler --namespace=kube-system
```

{{ output }}
deployment.apps "dns-autoscaler" deleted
{{ /output }}

**Second Option:**
Scale down the DNS-autoscaler deployment to 0 replicas

```bash
kubectl scale deployment --replicas=0 dns-autoscaler --namespace=kube-system
```

{{ output }}
deployment.extensions/dns-autoscaler scaled
{{ /output }}

**Check ReplicaSet for dns-autoscaler**

```bash
kubectl get rs -n kube-system -l k8s-app=dns-autoscaler
NAME                        DESIRED   CURRENT   READY   AGE
dns-autoscaler-7686459c58   0         0         0       1d
```
