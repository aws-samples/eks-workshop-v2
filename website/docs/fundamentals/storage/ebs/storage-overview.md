---
title: EKS Storage Overview
sidebar_position: 20
---

It's important to be familiar with some  concepts about [Kubernetes Storage](https://kubernetes.io/docs/concepts/storage/):
* [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/): On-disk files in a container are ephemeral, which presents some problems for non-trivial applications when running in containers. One problem is the loss of files when a container crashes. The kubelet restarts the container but with a clean state. A second problem occurs when sharing files between containers running together in a Pod. The Kubernetes volume abstraction solves both of these problems. Familiarity with Pods is suggested.
* [Ephemeral Volumes](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/) are designed for these use cases. Because volumes follow the Pod's lifetime and get created and deleted along with the Pod, Pods can be stopped and restarted without being limited to where some persistent volume is available. 
* [Persistent Volumes (PV)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) is a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It is a resource in the cluster just like a node is a cluster resource. PVs are volume plugins like Volumes, but have a lifecycle independent of any individual Pod that uses the PV. This API object captures the details of the implementation of the storage, be that NFS, iSCSI, or a cloud-provider-specific storage system.
* [Persistent Volume Claim (PVC)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) is a request for storage by a user. It is similar to a Pod. Pods consume node resources and PVCs consume PV resources. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes (e.g., they can be mounted ReadWriteOnce, ReadOnlyMany or ReadWriteMany, see AccessModes
* [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/) provides a way for administrators to describe the "classes" of storage they offer. Different classes might map to quality-of-service levels, or to backup policies, or to arbitrary policies determined by the cluster administrators. Kubernetes itself is unopinionated about what classes represent. This concept is sometimes called "profiles" in other storage systems.
* [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)  allows storage volumes to be created on-demand. Without dynamic provisioning, cluster administrators have to manually make calls to their cloud or storage provider to create new storage volumes, and then create PersistentVolume objects to represent them in Kubernetes. The dynamic provisioning feature eliminates the need for cluster administrators to pre-provision storage. Instead, it automatically provisions storage when it is requested by users.

**emptyDir is an example of ephemeral volumes, and we're currently utilizing it on the MySQL StatefulSet, but we'll work on updating it on this chapter to a Persistent Volume (PV) and Dynamic Volume Provisioning**

The [Kubernetes Container Storage Interface (CSI)](https://kubernetes-csi.github.io/docs/) helps you run stateful containerized applications. CSI drivers provide a CSI interface that allows Kubernetes clusters to manage the lifecycle of persistent volumes. Amazon EKS makes it easier for you to run stateful workloads by offering CSI drivers for Amazon EBS.

In order to utilize Amazon EBS volumes with dynamic provisioning on our EKS cluster, we need to confirm that we have the EBS CSI Driver installed. [The Amazon Elastic Block Store (Amazon EBS) Container Storage Interface (CSI) driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) allows Amazon Elastic Kubernetes Service (Amazon EKS) clusters to manage the lifecycle of Amazon EBS volumes for persistent volumes.

As part of our workshop environment, the EKS cluster has pre-installed the EBS CSI Driver. We can confirm the installation by running the following command:

```bash
$ kubectl get daemonset ebs-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
ebs-csi-node   3         3         3       3            3           kubernetes.io/os=linux   3d21h
```

We also already have our [storageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) object configured using [Amazon EBS GP2 volume type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose.html#EBSVolumeTypes_gp2). Run the following command to confirm:

```bash
$ kubectl get storageclass
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  3d22h
```

Now that we have a better understading of EKS Storage and Kubernetes objects. On the next page, we will focus on modifying the MySQL DB StatefulSet of the Catalog microservice to utilize a EBS block store volume as the persistent storage for the database files using Kubernetes Dynamic Volume Provisioning. 


