---
title: FSx for OpenZFS CSI Driver
sidebar_position: 20
---

Before diving into this section, you should be familiar with the Kubernetes storage objects (volumes, persistent volumes (PV), persistent volume claims (PVC), dynamic provisioning and ephemeral storage) that were introduced in the [Storage](../index.md) main section.

The [Amazon FSx for OpenZFS Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-fsx-openzfs-csi-driver) enables you to run stateful containerized applications by providing a CSI interface that allows Kubernetes clusters running on AWS to manage the lifecycle of Amazon FSx for OpenZFS file systems and volumes. The following architecture diagram illustrates how we will use Amazon FSx for OpenZFS as persistent storage for our EKS pods:

![Assets with FSx for OpenZFS](./assets/assets-fsxz.webp)

To utilize Amazon FSx for OpenZFS with dynamic provisioning on our EKS cluster, we first need to create an IAM role allowed to interact with FSx. Once the IAM role has been created we can install the CSI driver. The driver implements the CSI specification which allows container orchestrators to manage Amazon FSx for OpenZFS file systems and volumes throughout their lifecycle.

As part of the lab preparation, an IAM role has already been created for the CSI driver to call the appropriate AWS APIs.

We'll use Helm to add the repository and install the FSx for OpenZFS CSI driver with a chart:

```bash timeout=300 wait=60
$ helm repo add aws-fsx-openzfs-csi-driver https://kubernetes-sigs.github.io/aws-fsx-openzfs-csi-driver
$ helm repo update
$ helm upgrade --install aws-fsx-openzfs-csi-driver \
    --namespace kube-system --wait \
    --set "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$FSXZ_IAM_ROLE" \
    aws-fsx-openzfs-csi-driver/aws-fsx-openzfs-csi-driver
```

Let's examine what the chart has created in our EKS cluster. For example, a DaemonSet that runs a pod on each node in our cluster:

```bash
$ kubectl get daemonset fsx-openzfs-csi-node -n kube-system
NAME                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
fsx-openzfs-csi-node   3         3         3       3            3           kubernetes.io/os=linux        52s
```

The FSx for OpenZFS CSI driver supports both dynamic and static provisioning. For dynamic provisioning, the driver can create both an FSx for OpenZFS file system as well as a volume on an existing file system. Static provisioning allows association of a pre-created FSx for OpenZFS file system or volume with a PersistentVolume (PV) for consumption within Kubernetes. The driver also supports creation of NFS mount options, volume snapshots, and allows for volume resizing.

As a part of the lab preparation, the FSx for OpenZFS file system has already been created for your use.  In this lab you'll use dynamic provisioning by creating a [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) object configured to deploy an FSx for OpenZFS volume.

Now that we understand EKS StorageClasses and the FSx for OpenZFS CSI driver, we'll proceed to modify the assets microservice to use the FSx for OpenZFS StorageClass with Kubernetes dynamic provisioning to create a new volume for storing product images.
