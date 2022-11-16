---
title: Add and remove nodes
sidebar_position: 10
sidebar_custom_props: {"module": true}
---
While working with your cluster, you may need to update your managed node group configuration to add additional nodes to support the needs of your workloads. A nodegroup can be scaled using Amazon EKS Console OR  using `eksctl scale nodegroup` command.

 To edit your managed node group configuration using Amazon EKS Console, navigate to the Amazon EKS console at [https://console.aws.amazon.com/eks/home#/clusters](https://console.aws.amazon.com/eks/home#/clusters).

Next, click the `eks-workshop-cluster`, select the **Compute** tab, and select the node group to edit and choose **Edit**.

On the **Edit node group** page, you can see the following settings under **Node group scaling configuration**: **Desired size**, **Minimum size** and **Maximum size**. Bump the **Minimum size** *and* **Desired size** from `2` to `3`. Scroll down and hit **Save changes**.


![Added nodes in UI](../assets/added-nodes.png)


**Alternatively**, you can also change nodegroup configuration using `eksctl` command. To change your nodegroup configuration using `eksctl` command, first let's retrieve the current nodegroup scaling configuration and look at **minimum size**, **maximum size** and **desired capacity** of nodes using eksctl command below:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

We will scale the nodegroup in `eks-workshop-cluster` by changing the node count from `2` to `3` for **minimum size** and **desired capacity** using below command:
>Note: You do not need to run below command if you have changed the size of nodegroup using `Amazon EKS Console`.

```bash
$ eksctl scale nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME --nodes 3 --nodes-min 3 --nodes-max 6
```

:::tip
A node group can also be updated using the `aws` CLI with the following command. See the [docs](https://docs.aws.amazon.com/cli/latest/reference/eks/update-nodegroup-config.html) for more info.

```
aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config minSize=3,maxSize=6,desiredSize=3
```
:::

After making changes to the node group via `Amazon EKS Console` or `eksctl` command, it may take up to **2-3 minutes** for node provisioning and configuration changes to take effect. 
Let's retrieve the nodegroup configutation again and look at **minimum size**, **maximum size** and **desired capacity** of nodes using eksctl command below:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

You can also review changed worker node count with following command, which gets all nodes in our managed node group by using the label as a filter. It may take a few minutes for the new node to update:

```bash
$ kubectl get nodes -l eks.amazonaws.com/nodegroup=$EKS_DEFAULT_MNG_NAME
NAME                                         STATUS     ROLES    AGE    VERSION
ip-10-42-10-166.us-east-2.compute.internal   Ready      <none>   117m   v1.23.9-eks-ba74326
ip-10-42-11-171.us-east-2.compute.internal   Ready      <none>   117m   v1.23.9-eks-ba74326
ip-10-42-12-178.us-east-2.compute.internal   NotReady   <none>   19s    v1.23.9-eks-ba74326
```

To remove nodes, change the nodegroup configuration with command given below:

```bash
$ eksctl scale nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME --nodes 2 --nodes-min 2 --nodes-max 6
```

:::tip
A node group can also be scaled by using a config file passed to `--config-file` and specifying the name of the nodegroup that should be scaled with `--name`. `eksctl` will search the config file and discover that nodegroup as well as its scaling configuration values. See more info on the [eksctl docs](https://eksctl.io/usage/managing-nodegroups/).
