---
title: Add nodes
sidebar_position: 10
---
While working with your cluster, you may need to update your managed node group configuration to add additional nodes to support the needs of your workloads. There are many ways to scale a node group, in our case we will be using `eksctl scale nodegroup` command.

First let's retrieve the current nodegroup scaling configuration and look at **minimum size**, **maximum size** and **desired capacity** of nodes using `eksctl` command below:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

We'll scale the nodegroup in `eks-workshop` by changing the node count from `3` to `4` for **minimum size** and **desired capacity** using below command:

```bash wait=60
$ eksctl scale nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME \
    --nodes 4 --nodes-min 4 --nodes-max 6
```

:::tip
A node group can also be updated using the `aws` CLI with the following command. See the [docs](https://docs.aws.amazon.com/cli/latest/reference/eks/update-nodegroup-config.html) for more info.

```
aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config minSize=4,maxSize=6,desiredSize=4
```
:::

After making changes to the node group it may take up to **2-3 minutes** for node provisioning and configuration changes to take effect. Let's retrieve the nodegroup configuration again and look at **minimum size**, **maximum size** and **desired capacity** of nodes using `eksctl` command below:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

You can also review changed worker node count with following command, which lists all nodes in our managed node group by using the label as a filter:

:::tip
It can take a minute or so for the node to appear in the output below, if the list still shows 3 nodes be patient.
:::

```bash
$ kubectl get nodes -l eks.amazonaws.com/nodegroup=$EKS_DEFAULT_MNG_NAME
NAME                                            STATUS     ROLES    AGE     VERSION
ip-10-42-104-151.us-west-2.compute.internal   Ready      <none>   2d23h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-144-11.us-west-2.compute.internal    Ready      <none>   2d23h   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-146-166.us-west-2.compute.internal   NotReady   <none>   18s     vVAR::KUBERNETES_NODE_VERSION
ip-10-42-182-134.us-west-2.compute.internal   Ready      <none>   2d23h   vVAR::KUBERNETES_NODE_VERSION
```

Notice that the node shows a status of `NotReady`, which happens when the new node is still in the process of joining the cluster. We can also use `kubectl wait` to watch until all the nodes report `Ready`:

```bash hook=add-node
$ kubectl wait --for=condition=Ready nodes --all --timeout=300s
```
