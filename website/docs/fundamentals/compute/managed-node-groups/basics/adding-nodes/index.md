---
title: Add nodes
sidebar_position: 10
---

While working with your cluster, you may need to update your managed node group configuration to add additional nodes to support the needs of your workloads. There are many ways to scale a node group, in our case we will be using the `aws eks update-nodegroup-config` command.

First let's retrieve the current nodegroup scaling configuration and look at **minimum size**, **maximum size** and **desired capacity** of nodes using `eksctl` command below:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

We'll scale the nodegroup in `eks-workshop` by changing the node count from `3` to `4` for **desired capacity** using below command:

```bash
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config minSize=4,maxSize=6,desiredSize=4
```

After making changes to the node group it may take up to **2-3 minutes** for node provisioning and configuration changes to take effect. Let's retrieve the nodegroup configuration again and look at **minimum size**, **maximum size** and **desired capacity** of nodes using `eksctl` command below:

```bash hook=wait-node
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

Monitor the nodes in the cluster using the following command with the `--watch` argument until there are 4 nodes:

:::tip
It can take a minute or so for the node to appear in the output below, if the list still shows 3 nodes be patient.
:::

```bash test=false
$ kubectl get nodes --watch
NAME                                          STATUS     ROLES    AGE  VERSION
ip-10-42-104-151.us-west-2.compute.internal   Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-144-11.us-west-2.compute.internal    Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-146-166.us-west-2.compute.internal   NotReady   <none>   18s  vVAR::KUBERNETES_NODE_VERSION
ip-10-42-182-134.us-west-2.compute.internal   Ready      <none>   3h   vVAR::KUBERNETES_NODE_VERSION
```

Once 4 nodes are visible you can exit the watch using `Ctrl+C`.

You may see a node shows a status of `NotReady`, which happens when the new node is still in the process of joining the cluster.
