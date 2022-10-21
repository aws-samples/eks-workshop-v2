---
title: EFS CSI Driver
sidebar_position: 20
---

Before we dive into this section, make sure to familiarized yourself with the Kubernetes storage objects (volumes, persistent volumes (PV), persistent volume claim (PVC), dynamic provisioning and ephemeral storage) that were introduced on the [Storage](../index.md) main section.

The [Amazon Elastic File System Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver) helps you run stateful containerized applications. Amazon EFS Container Storage Interface (CSI) driver provide a CSI interface that allows Kubernetes clusters running on AWS to manage the lifecycle of Amazon EFS file systems.

In order to utilize Amazon EFS file system with dynamic provisioning on our EKS cluster, we need to confirm that we have the EFS CSI Driver installed. The [Amazon Elastic File System Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver) implements the CSI specification for container orchestrators to manage the lifecycle of Amazon EFS file systems.

> Optional: 
> To learn how to install the Amazon Elastic File System Container Storage Interface (CSI) Driver] on a non-workshop cluster, follow the instructions in our documentation.

As part of our workshop environment, the EKS cluster has pre-installed the Amazon Elastic File System Container Storage Interface (CSI) Driver. We can confirm the installation by running the following command:

```bash
$ kubectl get daemonset efs-csi-node -n kube-system

NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
efs-csi-node   3         3         3       3            3           beta.kubernetes.io/os=linux   2d1h
```

EFS CSI driver supports dynamic provisioning and static provisioning. Currently Dynamic Provisioning creates an access point for each PV. This mean an AWS EFS file system has to be created manually on AWS first and should be provided as an input to the storage class parameter. For static provisioning, AWS EFS file system needs to be created manually on AWS first. After that it can be mounted inside a container as a volume using the driver.

As part of our workshop environement, we have created EFS file system, mount targets and required security group with an inbound rule that allows inbound NFS traffic for your Amazon EFS mount points. you can get the EFS file system ID by running the following command:


```bash
$ aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text

fs-061cb5c5ed841a6b0
```

Now we Will need to create [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) object configured using the previously created [Amazon Elastic File System](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) as part of this workshop infrastructure and use [EFS Access points](https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html) as provisioning mode.

First you will need to Edit the file modules/fundamentals/storage/efs/efsstorageclass.yaml. Find the following line and replace the value for fileSystemId with your file system ID.

```blank

  fileSystemId: <filesystemid>
  
```

Second you will need to run the below command to create the storage class.

```bash
$ kubectl apply -f modules/fundamentals/storage/efs/efsstorageclass.yaml

storageclass.storage.k8s.io/efs-sc created
```
Now if you want you can get and describe the storage class use the below command, you will notice that provisioner used is the EFS CSI driver and Provisioning mode is EFS Access point.

```bash
$ kubectl get storageclass

NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  8m29s
```

```bash
$ kubectl describe sc efs-sc

Name:            efs-sc
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"efs-sc"},"parameters":{"directoryPerms":"700","fileSystemId":"fs-061cb5c5ed841a6b0","provisioningMode":"efs-ap"},"provisioner":"efs.csi.aws.com"}

Provisioner:           efs.csi.aws.com
Parameters:            directoryPerms=700,fileSystemId=fs-061cb5c5ed841a6b0,provisioningMode=efs-ap
AllowVolumeExpansion:  <unset>
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

Now that we have a better understading of EKS Storage Class and EFS CSI driver. On the next page, we will focus on modifying the Nginx deployment of the assets microservice to utilize the created Storage class using Kubernetes Dynamic Volume Provisioning to have a persistentvolume to store the product images. 