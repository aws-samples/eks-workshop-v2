---
title: EFS CSI Driver
sidebar_position: 20
---

Before we dive into this section, make sure to familiarized yourself with the Kubernetes storage objects (volumes, persistent volumes (PV), persistent volume claim (PVC), dynamic provisioning and ephemeral storage) that were introduced on the [Storage](../index.md) main section.

The [Amazon Elastic File System Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver) helps you run stateful containerized applications. Amazon EFS Container Storage Interface (CSI) driver provide a CSI interface that allows Kubernetes clusters running on AWS to manage the lifecycle of Amazon EFS file systems.

In order to utilize Amazon EFS file system with dynamic provisioning on our EKS cluster, we need to confirm that we have the EFS CSI Driver installed. The [Amazon Elastic File System Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver) implements the CSI specification for container orchestrators to manage the lifecycle of Amazon EFS file systems.

As part of our workshop environment the EKS cluster has the Amazon Elastic File System Container Storage Interface (CSI) Driver pre-installed. We can confirm the installation like so:

```bash
$ kubectl get daemonset efs-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
efs-csi-node   3         3         3       3            3           beta.kubernetes.io/os=linux   2d1h
```

The EFS CSI driver supports dynamic and static provisioning. Currently dynamic provisioning creates an access point for each PersistentVolume. This mean an AWS EFS file system has to be created manually on AWS first and should be provided as an input to the StorageClass parameter. For static provisioning, AWS EFS file system needs to be created manually on AWS first. After that it can be mounted inside a container as a volume using the driver.

The workshop environment also has an EFS file system, mount targets and the required security group pre-provisioned with an inbound rule that allows inbound NFS traffic for your Amazon EFS mount points. You can retrieve information about the EFS file system by running the following AWS CLI command:

```bash
$ aws efs describe-file-systems --file-system-id $EFS_ID
```

Now, we'll need to create a StorageClass(https://kubernetes.io/docs/concepts/storage/storage-classes/) object configured to use the pre-provisioned EFS file system as part of this workshop infrastructure and use [EFS Access points](https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html) in provisioning mode.

We'll be using Kustomize to create for us the storage class and to ingest the environment variable `EFS_ID` in the parameter `filesystemid` value in the configuration of the storage class object: 

```kustomization
fundamentals/storage/efs/storageclass/efsstorageclass.yaml
StorageClass/efs-sc
```

Let's apply this kustomization:

```bash
$ kubectl apply -k /workspace/modules/fundamentals/storage/efs/storageclass
storageclass.storage.k8s.io/efs-sc created
configmap/assets-efsid-48hg67g6fd created
```

Now we'll get and describe the StorageClass using the below commands. Notice that the provisioner used is the EFS CSI driver and the provisioning mode is EFS access point and ID of the file system as exported in the `EFS_ID` environment variable.

```bash
$ kubectl get storageclass
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  8m29s
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

Now that we have a better understanding of EKS StorageClass and EFS CSI driver. On the next page, we'll focus on modifying the asset microservice to leverage the EFS `StorageClass` using Kubernetes dynamic volume provisioning and a PersistentVolume to store the product images. 
