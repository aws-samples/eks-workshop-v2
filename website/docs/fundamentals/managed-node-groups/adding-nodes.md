---
title: Add and remove nodes
sidebar_position: 10
---
While working with your cluster, you may need to update your managed node group configuration to add additional nodes to support the needs of your workloads. A nodegroup can be scaled using Amazon EKS Console OR  using `eksctl scale nodegroup` command.

 To edit your managed node group configuration using Amazon EKS Console, navigate to the Amazon EKS console at [https://console.aws.amazon.com/eks/home#/clusters](https://console.aws.amazon.com/eks/home#/clusters).

Next, click the `eks-workshop-cluster`, select the **Compute** tab, and select the node group to edit and choose **Edit**.

On the **Edit node group** page, you can see the following settings under **Node group scaling configuration**: **Desired size**, **Minimum size** and **Maximum size**. Bump the **minimum size** *and* **desired size** from `2` to `3`. Scroll down and hit **Save changes**.


![Added nodes in UI](./assets/added-nodes.png)


**Alternatively**, You can also change nodegroup configuration using `eksctl` command. To change your nodegroup configuration using `eksctl` command, first let's retrieve the current nodegroup scaling configuration and look at `MIN SIZE`, `MAX SIZE` and `DESIRED CAPACITY` of nodes using eksctl command below:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

We will scale the nodegroup in `eks-workshop-cluster` by changing the node count from `2` to `3` for `MIN SIZE` and `DESIRED CAPACITY` using below command:
>Note: You do not need to run below command, if you have changed the size of nodegroup using `Amazon EKS Console`.

```bash
$ eksctl scale nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME --nodes 3 --nodes-min 3 --nodes-max 6
```


After making changes to nodegroup via `Amazon EKS Console ` or `eksctl` command, it may take upto **2-3 minutes** for node provisioning and configuration changes to take effect. 
Let's retrieve the nodegroup configutation again and look at `MIN SIZE`, `MAX SIZE` and `DESIRED CAPACITY` of nodes using eksctl command below:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

You can also review changed **Kubernetes** node count with following command:

```bash
$ kubectl get nodes
```

To remove nodes, change the nodegroup configuration with command given below:

```bash
$ eksctl scale nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME --nodes 2 --nodes-min 2 --nodes-max 6
```


> Note: A nodegroup can also be scaled by using a config file passed to `--config-file` and specifying the name of the nodegroup that should be scaled with `--name`. Eksctl will search the config file and discover that nodegroup as well as its scaling configuration values.
