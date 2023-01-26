---
title: "Autoscaling CoreDNS"
date: 2022-07-21T00:00:00-03:00
sidebar_position: 3
---

`CoreDNS` is the default DNS service for Kubernetes that runs in Pods with the label `k8s-app=kube-dns`. In this lab exercise, we'll autoscale CoreDNS based on the number of schedulable nodes and cores of our cluster. Cluster Proportional Autoscaler will resize the number of `CoreDNS` replicas.

Currently we're running a 3 node cluster:

```bash
$ kubectl get nodes
NAME                                            STATUS   ROLES    AGE   VERSION
ip-192-168-109-155.us-east-2.compute.internal   Ready    <none>   76m   v1.23.9-eks-810597c
ip-192-168-142-113.us-east-2.compute.internal   Ready    <none>   76m   v1.23.9-eks-810597c
ip-192-168-80-39.us-east-2.compute.internal     Ready    <none>   76m   v1.23.9-eks-810597c
```

Based on autoscaling parameters defined in the `ConfigMap`, we see cluster proportional autoscaler scale `CoreDNS` to 2 replicas:

```bash
$ kubectl get po -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-5db97b446d-5zwws   1/1     Running   0          66s
coredns-5db97b446d-n5mp4   1/1     Running   0          89m
```

If we increased the size of the EKS cluster to 5 nodes, Cluster Proportional Autoscaler will scale up the number of replicas of `CoreDNS` to accommodate for it:

```bash hook=cpa-pod-scaleout timeout=300
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config desiredSize=$(($EKS_DEFAULT_MNG_DESIRED+2))
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME
$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
```

Kubernetes now shows the 5 nodes in a `Ready` state:

```bash
$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-42-10-248.us-west-2.compute.internal    Ready    <none>   61s   v1.23.9-eks-810597c
ip-10-42-10-29.us-west-2.compute.internal     Ready    <none>   124m  v1.23.9-eks-810597c
ip-10-42-11-109.us-west-2.compute.internal    Ready    <none>   6m39s v1.23.9-eks-810597c
ip-10-42-11-152.us-west-2.compute.internal    Ready    <none>   61s   v1.23.9-eks-810597c
ip-10-42-12-139.us-west-2.compute.internal    Ready    <none>   6m20s v1.23.9-eks-810597c
```

And we can see that the number of `CoreDNS` Pods has increased:

```bash
$ kubectl get po -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-657694c6f4-klj6w   1/1     Running   0          14h
coredns-657694c6f4-tdzsd   1/1     Running   0          54s
coredns-657694c6f4-wmnnc   1/1     Running   0          14h
```

You can take a look at the CPA logs to see how it responded to the change in the number of nodes in our cluster:

```bash
$ kubectl logs deploy/dns-autoscaler -n other
{"includeUnschedulableNodes":true,"max":6,"min":2,"nodesPerReplica":2,"preventSinglePointFailure":true}
I0801 15:02:45.330307       1 k8sclient.go:272] Cluster status: SchedulableNodes[1], SchedulableCores[2]
I0801 15:02:45.330328       1 k8sclient.go:273] Replicas are not as expected : updating replicas from 2 to 3
```
