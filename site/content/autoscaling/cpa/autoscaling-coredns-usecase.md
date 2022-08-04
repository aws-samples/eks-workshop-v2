---
title: "Autoscaling CoreDNS Using Cluster Proportional Autoscaler"
date: 2022-07-21T00:00:00-03:00
weight: 3
---

### Autoscaling CoreDNS

`CoreDNS` is the default DNS service for kubernetes. The label set for CoreDNS is `k8s-app=kube-dns`

**In this example, we will autoscale CoreDNS based on the number of schedulable nodes and cores of the cluster. Cluster proportional autoscaler will resize the number of `CoreDNS` replicas**

**In the installation section, we installed `dns-autoscaler` and chose `CoreDNS` as the deployment target for the cluster proportional autoscaler**

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

**Get CPA autoscaling parameters**

```bash
kubectl get configmap -n kube-system
```

{{< output >}}
NAME                                 DATA   AGE
aws-auth                             1      1d
coredns                              1      1d
cp-vpc-resource-controller           0      1d
dns-autoscaler                       1      1d
eks-certificates-controller          0      1d
extension-apiserver-authentication   6      1d
kube-proxy                           1      1d
kube-proxy-config                    1      1d
kube-root-ca.crt                     1      1d
{{< /output >}}

Describe the **dns-autoscaler** ConfigMap

```bash
kubectl describe configmap dns-autoscaler -n kube-system
```

{{< output >}}
Name:         dns-autoscaler
Namespace:    kube-system
Labels:       <none>
Annotations:  <none>

Data
====
linear:
----
{"coresPerReplica":2,"includeUnschedulableNodes":true,"nodesPerReplica":1,"preventSinglePointFailure":true,"min":1,"max":4}
Events:  <none>

{{< /output >}}

**Currently we are running a 3 node cluster and based on autoscaling parameters defined in the ConfigMap, we see cluster proportional autoscaler added 3 replicas of CoreDNS**

```bash
kubectl get nodes
```

{{< output >}}
NAME                                            STATUS   ROLES    AGE   VERSION
ip-192-168-109-155.us-east-2.compute.internal   Ready    <none>   76m   v1.22.9-eks-810597c
ip-192-168-142-113.us-east-2.compute.internal   Ready    <none>   76m   v1.22.9-eks-810597c
ip-192-168-80-39.us-east-2.compute.internal     Ready    <none>   76m   v1.22.9-eks-810597c
{{< /output >}}

**Export Nodegroup name**

```bash
export EKS_NODEGROUP_NAME=$(aws eks list-nodegroups --cluster-name $EKS_CLUSTER_NAME --query "nodegroups[0]" --output text)
```

**Display the current Nodgroup size configurations**
```bash
aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODEGROUP_NAME --query nodegroup.scalingConfig --output table
```

{{ output }}
---------------------------------------
|          DescribeNodegroup          |
+-------------+-----------+-----------+
| desiredSize |  maxSize  |  minSize  |
+-------------+-----------+-----------+
|  3          |  5        |  3        | 
+-------------+-----------+-----------+

{{ /output }}

**Check current CoreDNS replicas**

```bash
kubectl get po -n kube-system -l k8s-app=kube-dns
```

{{ output }}
NAME                       READY   STATUS    RESTARTS   AGE
coredns-5db97b446d-5zwws   1/1     Running   0          66s
coredns-5db97b446d-n5mp4   1/1     Running   0          89m
coredns-5db97b446d-svknx   1/1     Running   0          86s
{{ /output }}


**If we reduce the size of the cluster to a single node, cluster proportional autoscaler will resize the CoreDNS to just run a single replica as we are reducing the cluster size from 3 nodes to a single node**

```bash
aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_NODEGROUP_NAME  --scaling-config minSize=1,maxSize=5,desiredSize=1
```
{{ output }}
---------------------------------------
|          DescribeNodegroup          |
+-------------+-----------+-----------+
| desiredSize |  maxSize  |  minSize  |
+-------------+-----------+-----------+
|  1          |  5        |  1        | 
+-------------+-----------+-----------+
{{ /output }}

**Check worker nodes and CoreDNS pods**

```bash
kubectl get nodes
```
{{< output >}}
NAME                                          STATUS   ROLES    AGE   VERSION
ip-192-168-80-39.us-east-2.compute.internal   Ready    <none>   83m   v1.22.9-eks-810597c
{{< /output >}}

```bash
kubectl get po -n kube-system -l k8s-app=kube-dns
```
{{ output }}
NAME                       READY   STATUS    RESTARTS   AGE
coredns-5db97b446d-n5mp4   1/1     Running   0          84m
{{ /output }}


**Check Cluster proportional autoscaler logs to ensure it resized CoreDNS replicas from 3 to 1**

```bash
kubectl get po -n kube-system -l k8s-app=dns-autoscaler
```

{{ output }}
NAME                              READY   STATUS    RESTARTS   AGE
dns-autoscaler-7686459c58-bbjgk   1/1     Running   0          63m
{{ /output }}

**Check Cluster proportional autoscaler logs**

```bash
kubectl logs deploy/dns-autoscaler -n kube-system
```

**In the output you will see CPA resizing CoreDNS replicas from 3 to 1**

{{ output }}
{"coresPerReplica":2,"includeUnschedulableNodes":true,"nodesPerReplica":1,"preventSinglePointFailure":true,"min":1,"max":4}
I0801 15:02:45.330307       1 k8sclient.go:272] Cluster status: SchedulableNodes[1], SchedulableCores[2]
I0801 15:02:45.330328       1 k8sclient.go:273] Replicas are not as expected : updating replicas from 3 to 2
I0801 15:03:15.330855       1 k8sclient.go:272] Cluster status: SchedulableNodes[1], SchedulableCores[2]
I0801 15:03:15.330875       1 k8sclient.go:273] Replicas are not as expected : updating replicas from 2 to 1
{{ /output }}









