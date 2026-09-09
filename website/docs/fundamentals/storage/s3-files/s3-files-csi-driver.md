---
title: S3 Files CSI Driver
sidebar_position: 20
---

Before diving into this section, you should be familiar with the Kubernetes storage objects (volumes, persistent volumes (PV), persistent volume claims (PVC), dynamic provisioning and ephemeral storage) that were introduced in the main [Storage](../index.md) section.

Amazon S3 Files uses the [Amazon EFS Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver) (version 3.0.0+) to mount S3 file systems on Amazon EKS clusters. The same driver that supports Amazon EFS also supports S3 Files, since S3 Files is built on Amazon EFS technology and uses the NFS protocol.

The following architecture diagram illustrates how we will use S3 Files as persistent storage for our EKS pods:

![Assets with S3 Files](/docs/fundamentals/storage/s3-files/s3-files-storage.webp)

To utilize Amazon S3 Files on our EKS cluster, we first need to confirm that we have the EFS CSI Driver installed. The driver implements the CSI specification which allows container orchestrators to manage both Amazon EFS and S3 file systems throughout their lifecycle.

Since the required IAM roles have already been created for us, we can proceed with installing the add-on:

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver \
  --service-account-role-arn $S3_FILES_CSI_ADDON_ROLE
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name aws-efs-csi-driver
```

Let's examine what the add-on has created in our EKS cluster. For example, a DaemonSet that runs a Pod on each node in our cluster:

```bash
$ kubectl get daemonset efs-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
efs-csi-node   3         3         3       3            3           kubernetes.io/os=linux        47s
```

Now that we've confirmed the EFS CSI driver is installed and running, let's look at how it can provision storage for our S3 file system, and why we'll use static provisioning.
