---
title: Add and remove nodes
sidebar_position: 10
---
While working with your cluster, you may need to update your managed node group configuration to add additional nodes to support the needs of your workloads. A nodegroup can be scaled by using the `eksctl scale nodegroup` command.

First let's retrieve the current nodegroup scaling configuration and look at `MIN SIZE`, `MAX SIZE` and `DESIRED CAPACITY` of nodes using eksctl command below:

```bash
$ eksctl get nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME
```

We will scale the nodegroup in `eks-workshop-cluster` by incrementing the current node count by **1** for `MIN SIZE` and `DESIRED CAPACITY`.

```bash
$ eksctl scale nodegroup --name $EKS_DEFAULT_MNG_NAME --cluster $EKS_CLUSTER_NAME --nodes 3 --nodes-min 3 --nodes-max 6
```
It may take upto **2-3 minutes** for node provisioning and configuration changes to take effect. Let's retrieve the nodegroup configutation again and look at `MIN SIZE`, `MAX SIZE` and `DESIRED CAPACITY` of nodes using eksctl command below:

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
