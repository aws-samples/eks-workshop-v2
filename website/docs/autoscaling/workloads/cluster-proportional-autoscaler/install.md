---
title: "Autoscaling CoreDNS"
date: 2022-07-21T00:00:00-03:00
sidebar_position: 2
---

CoreDNS is the default DNS service for Kubernetes that runs in Pods with the label `k8s-app=kube-dns`. In this lab exercise we'll scale CoreDNS based on the number of schedulable nodes and cores of our cluster. Cluster Proportional Autoscaler will resize the number of CoreDNS replicas.

First lets install CPA using its Helm chart. We'll use the following `values.yaml` file to configure CPA:

```file
manifests/modules/autoscaling/workloads/cpa/values.yaml
```

We summarized how linear scaling works with CPA in the previous section. We can see that we're configuring it to:

- Target the deployment `coredns`
- Add a replica for every 2 worker nodes in the cluster
- Run at least 2 replicas and to most 6

:::warning

The configuration above should not be considered best practice for automatically scaling CoreDNS, it is an example that is easy to demonstrate for the purposes of the workshop.

:::

Install the chart:

```bash
$ helm repo add cluster-proportional-autoscaler https://kubernetes-sigs.github.io/cluster-proportional-autoscaler
$ helm upgrade --install cluster-proportional-autoscaler cluster-proportional-autoscaler/cluster-proportional-autoscaler \
  --namespace kube-system \
  --version "${CPA_CHART_VERSION}" \
  --set "image.tag=v${CPA_VERSION}" \
  --values ~/environment/eks-workshop/modules/autoscaling/workloads/cpa/values.yaml \
  --wait
NAME: cluster-proportional-autoscaler
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

This will create a `Deployment` in the `kube-system` namespace which we can inspect:

```bash
$ kubectl get deployment cluster-proportional-autoscaler -n kube-system
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
cluster-proportional-autoscaler   1/1     1            1           92s
```
