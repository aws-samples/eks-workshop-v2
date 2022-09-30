---
title: Add and remove nodes
sidebar_position: 10
---
While working with your cluster, you may need to update your managed node group configuration to add additional nodes to support the needs of your workloads. To edit your managed node group configuration, navigate to the Amazon EKS console at [https://console.aws.amazon.com/eks/home#/clusters](https://console.aws.amazon.com/eks/home#/clusters).

Next, click the `eks-workshop-cluster`, select the **Compute** tab, and select the node group to edit and choose **Edit**.

On the Edit node group page, you can see the following settings under **Node group scaling configuration**: **Desired size**, **Minimum size** and **Maximum size**. Bump the **minimum size** *and* **desired size** from `3` to `4`. Scroll down and hit **Save changes**.

> Note: You can also edit **Tags** and **Kubernetes labels** on this page. Labels are defined within the Kubernetes API, and are generally used to define which nodes you want pods to run. Tags are assigned to the EKS node group object, but not the nodes themselves. Tags are used for a number of purposes, including auto-discovery by the cluster-autoscaler and to control access to the node group using AWS IAM policies.

![Added nodes in UI](./assets/added-nodes.png)

Wait a few seconds and run the following command again:

```bash
$ eksctl get nodegroup --cluster eks-workshop-cluster
```

You should see the updated configuration with the new desired capacity and minimum size. Wait about 3-4 minutes and run the following command:

```bash
$ kubectl get nodes
```

You should see 4 nodes in your managed node group instead of 3, in addition to the existing two fargate nodes.

To remove nodes, follow the same steps to edit the managed node group, but this time set the **minimum size** and **desired size** to `3`.