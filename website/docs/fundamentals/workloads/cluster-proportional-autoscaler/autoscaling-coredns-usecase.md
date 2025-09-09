---
title: "Triggering autoscaling"
date: 2022-07-21T00:00:00-03:00
sidebar_position: 3
---

Let's test the Cluster Proportional Autoscaler (CPA) that we installed in the previous section. Currently we're running a 3 node cluster:

```bash
$ kubectl get nodes
NAME                                            STATUS   ROLES    AGE   VERSION
ip-10-42-109-155.us-east-2.compute.internal     Ready    <none>   76m   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-142-113.us-east-2.compute.internal     Ready    <none>   76m   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-80-39.us-east-2.compute.internal       Ready    <none>   76m   vVAR::KUBERNETES_NODE_VERSION
```

Based on the autoscaling parameters defined in our configuration, we can see the CPA has scaled CoreDNS to 2 replicas:

```bash
$ kubectl get po -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-5db97b446d-5zwws   1/1     Running   0          66s
coredns-5db97b446d-n5mp4   1/1     Running   0          89m
```

If we increase the size of the EKS cluster to 5 nodes, the Cluster Proportional Autoscaler will automatically scale up the number of CoreDNS replicas to accommodate the additional nodes:

```bash hook=cpa-pod-scaleout timeout=300
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config desiredSize=$(($EKS_DEFAULT_MNG_DESIRED+2))
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME
$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
```

Kubernetes now shows all 5 nodes in a `Ready` state:

```bash
$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-42-10-248.us-west-2.compute.internal    Ready    <none>   61s   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-29.us-west-2.compute.internal     Ready    <none>   124m  vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-109.us-west-2.compute.internal    Ready    <none>   6m39s vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-152.us-west-2.compute.internal    Ready    <none>   61s   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-139.us-west-2.compute.internal    Ready    <none>   6m20s vVAR::KUBERNETES_NODE_VERSION
```

And we can see that the number of CoreDNS Pods has increased to 3, based on our configuration of one replica per 2 nodes:

```bash
$ kubectl get po -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-657694c6f4-klj6w   1/1     Running   0          14h
coredns-657694c6f4-tdzsd   1/1     Running   0          54s
coredns-657694c6f4-wmnnc   1/1     Running   0          14h
```

You can examine the CPA logs to see how it responded to the change in the number of nodes in our cluster:

```bash
$ kubectl logs deployment/cluster-proportional-autoscaler -n kube-system
{"includeUnschedulableNodes":true,"max":6,"min":2,"nodesPerReplica":2,"preventSinglePointFailure":true}
I0801 15:02:45.330307       1 k8sclient.go:272] Cluster status: SchedulableNodes[1], SchedulableCores[2]
I0801 15:02:45.330328       1 k8sclient.go:273] Replicas are not as expected : updating replicas from 2 to 3
```

The logs confirm that the CPA detected the change in cluster size and adjusted the number of CoreDNS replicas accordingly.
