---
title: FSxN CSI Driver
sidebar_position: 20
---

Before we dive into this section, make sure to familiarized yourself with the Kubernetes storage objects (volumes, persistent volumes (PV), persistent volume claim (PVC), dynamic provisioning and ephemeral storage) that were introduced on the [Storage](../index.md) main section.

The [Amazon FSx for NetApp ONTAP Container Storage Interface (CSI) Driver](https://github.com/NetApp/trident) helps you run stateful containerized applications. Amazon FSx for NetApp ONTAP Container Storage Interface (CSI) driver provide a CSI interface that allows Kubernetes clusters running on AWS to manage the lifecycle of Amazon FSx for NetApp ONTAP file systems.

In order to utilize Amazon FSx for NetApp ONTAP file system with dynamic provisioning on our EKS cluster, we need to confirm that we have the Amazon FSx for NetApp ONTAP CSI Driver installed. The [Amazon FSx for NetApp ONTAP Container Storage Interface (CSI) Driver](https://github.com/NetApp/trident) implements the CSI specification for container orchestrators to manage the lifecycle of Amazon FSx for NetApp ONTAP file systems.

We can install the Amazon FSxN for NetApp ONTAP Trident CSI driver using helm. We will need to provide a required IAM role that has already been created for us as part fo the preperation for the workshop. 
```bash
$ helm repo add netapp-trident https://netapp.github.io/trident-helm-chart
$ helm install trident-operator netapp-trident/trident-operator --version 100.2410.0 --namespace trident --set cloudProvider=$CLOUD_PROVIDER --set cloudIdentity="$CLOUD_IDENTITY"
```


We can confirm the installation like so:

```bash
$ kubectl get pods -n trident
NAME                                READY   STATUS    RESTARTS   AGE
trident-controller-b6b5899-kqdjh    6/6     Running   0          87s
trident-node-linux-9q4sj            2/2     Running   0          86s
trident-node-linux-bxg5s            2/2     Running   0          86s
trident-node-linux-z92x2            2/2     Running   0          86s
trident-operator-588c7c854d-t4c4x   1/1     Running   0          102s
```

The FSx for NetApp ONTAP CSI driver supports dynamic and static provisioning. Currently dynamic provisioning creates an access point for each PersistentVolume. This mean an AWS EFS file system has to be created manually on AWS first and should be provided as an input to the StorageClass parameter. For static provisioning, AWS EFS file system needs to be created manually on AWS first. After that it can be mounted inside a container as a volume using the driver.

The workshop environment also has an FSx for NetApp ONTAP file system, Storage Virtual Machine (SVM) and the required security group pre-provisioned with an inbound rule that allows inbound NFS traffic for your Pods. You can retrieve information about the FSx for NetApp ONTAP file system by running the following AWS CLI command:

```bash
$ aws fsx describe-file-systems --file-system-id $FSXN_ID
```

Now, we'll need to create a TridentBackendConfig object configured to use the pre-provisioned FSx for NetApp ONTAP file system as part of this workshop infrastructure.

We'll be using Kustomize to create the backend and to ingest the following environment variables values in the configuration of the trident backend config object:
 - `SVM_NAME` in the parameter`fsxFilesystemID`
 - `FSXN_ID` in the parameter`svm`
 - `FSXN_SECRET` in the parameter`credentials.name`

```file
manifests/modules/fundamentals/storage/fsxn/backend/fsxn-backend-nas.yaml
```

Let's apply this kustomization:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/backend \
  | envsubst | kubectl apply -f-
tridentbackendconfig.trident.netapp.io/backend-tbc-ontap-nas created
```

Now we'll get check that the TridentBackendConfig was create using the below command:

```bash
$ kubectl get tbc -n trident
NAME                    BACKEND NAME    BACKEND UUID                           PHASE   STATUS
backend-tbc-ontap-nas   tbc-ontap-nas   bbae8686-25e4-4fca-a4c7-7ab664c7db9c   Bound   Success
```

Now, we'll need to create a [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) object

We'll be using Kustomize to create for the storage class:

```file
manifests/modules/fundamentals/storage/fsxn/storageclass/fsxnstorageclass.yaml
```

Let's apply this StorageClass:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/storageclass/fsxnstorageclass.yaml
storageclass.storage.k8s.io/fsxn-sc-nfs created
```

Now we'll get and describe the StorageClass using the below commands. Notice that the provisioner used is the `csi.trident.netapp.io` driver and the provisioning mode is `ontap-nas`.

```bash
$ kubectl get storageclass fsxn-sc-nfs
NAME          PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
fsxn-sc-nfs   csi.trident.netapp.io   Delete          Immediate           true                   39s

$ kubectl describe sc fsxn-sc-nfs
Name:            fsxn-sc-nfs
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"allowVolumeExpansion":true,"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"fsxn-sc-nfs"},"parameters":{"backendType":"ontap-nas"},"provisioner":"csi.trident.netapp.io"}

Provisioner:           csi.trident.netapp.io
Parameters:            backendType=ontap-nas
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

Now that we have a better understanding of EKS StorageClass and FSxN CSI driver. On the next page, we'll focus on modifying the asset microservice to leverage the FSxN `StorageClass` using Kubernetes dynamic volume provisioning and a PersistentVolume to store the product images.
