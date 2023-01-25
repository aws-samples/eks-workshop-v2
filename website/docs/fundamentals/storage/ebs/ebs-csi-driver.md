---
title: EBS CSI Driver
sidebar_position: 20
---

Before we dive into this section, make sure to familiarized yourself with the Kubernetes storage objects (volumes, persistent volumes (PV), persistent volume claim (PVC), dynamic provisioning and ephemeral storage) that were introduced on the [Storage](../index.md) main section.

[**emptyDir**](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) is an example of ephemeral volumes, and we're currently utilizing it on the MySQL StatefulSet, but we'll work on updating it on this chapter to a Persistent Volume (PV) using Dynamic Volume Provisioning.

The [Kubernetes Container Storage Interface (CSI)](https://kubernetes-csi.github.io/docs/) helps you run stateful containerized applications. CSI drivers provide a CSI interface that allows Kubernetes clusters to manage the lifecycle of persistent volumes. Amazon EKS makes it easier for you to run stateful workloads by offering CSI drivers for Amazon EBS.

In order to utilize Amazon EBS volumes with dynamic provisioning on our EKS cluster, we need to confirm that we have the EBS CSI Driver installed. [The Amazon Elastic Block Store (Amazon EBS) Container Storage Interface (CSI) driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) allows Amazon Elastic Kubernetes Service (Amazon EKS) clusters to manage the lifecycle of Amazon EBS volumes for persistent volumes.

> Optional: 
> To learn how to install the Amazon EBS CSI driver on a non-workshop cluster, follow the instructions in our documentation.

As part of our workshop environment, the EKS cluster has pre-installed the EBS CSI Driver. We can confirm the installation by running the following command:

```bash
$ kubectl get daemonset ebs-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
ebs-csi-node   3         3         3       3            3           kubernetes.io/os=linux   3d21h
```

We also already have our [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) object configured using [Amazon EBS GP2 volume type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose.html#EBSVolumeTypes_gp2). Run the following command to confirm:

```bash
$ kubectl get storageclass
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  3d22h
```

Now that we have a better understanding of EKS Storage and Kubernetes objects. On the next page, we'll focus on modifying the MySQL DB StatefulSet of the catalog microservice to utilize a EBS block store volume as the persistent storage for the database files using Kubernetes dynamic volume provisioning.
