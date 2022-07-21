---
title: "Autoscaling CoreDNS Using Cluster Proportional Autoscaler"
date: 2022-07-21T00:00:00-03:00
weight: 3
---

### Autoscaling CoreDNS

`CoreDNS` is the default DNS service for kubernetes. The label set for CoreDNS is `k8s-app=kube-dns`

In this example, we will autoscale CoreDNS based on the number of schedulable nodes and cores of the cluster. Cluster proportional autoscaler will resize the number of `CoreDNS` replicas

In the installation section, we installed `dns-autoscaler` and chose `CoreDNS` as the deployment target for the cluster proportional autoscaler

```bash
kubectl get po -n kube-system -l k8s-app=kube-dns
```
{{< output >}}
NAME                              READY   STATUS    RESTARTS   AGE
coredns-5db97b446d-k2rgr          1/1     Running   0          120m
{{< /output >}}

#### How to enable DNS autoscaling horizontally

CPA pods use `k8s.gcr.io/cpa/cluster-proportional-autoscaler:1.8.5` image that watches over the number of schedulable nodes and cores of the cluster and resizes the number of `CoreDNS` replicas as we chose CoreDNS as the target deployment for the CPA

```bash
kubectl get deployment dns-autoscaler -n kube-system
```
Output will look like:

{{< output >}}
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
dns-autoscaler   1/1     1            1           10s
{{< /output >}}

```bash
kubectl get po -n kube-system -l k8s-app=dns-autoscaler
```

Output will look like:

{{< output >}}
NAME                              READY   STATUS    RESTARTS   AGE
dns-autoscaler-7686459c58-cn97f   1/1     Running   0          1m
{{< /output >}}

**Tune DNS autoscaling parameters**
