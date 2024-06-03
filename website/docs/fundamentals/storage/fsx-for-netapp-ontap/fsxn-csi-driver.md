---
title: FSxN CSI Driver
sidebar_position: 20
---

Before we dive into this section, make sure to familiarized yourself with the Kubernetes storage objects (volumes, persistent volumes (PV), persistent volume claim (PVC), dynamic provisioning and ephemeral storage) that were introduced on the [Storage](../index.md) main section.

The [Amazon FSx for NetApp ONTAP Container Storage Interface (CSI) Driver](https://github.com/NetApp/trident) helps you run stateful containerized applications. Amazon FSx for NetApp ONTAP Container Storage Interface (CSI) driver provide a CSI interface that allows Kubernetes clusters running on AWS to manage the lifecycle of Amazon FSx for NetApp ONTAP file systems.

In order to utilize Amazon FSx for NetApp ONTAP file system with dynamic provisioning on our EKS cluster, we need to confirm that we have the Amazon FSx for NetApp ONTAP CSI Driver installed. The [Amazon FSx for NetApp ONTAP Container Storage Interface (CSI) Driver](https://github.com/NetApp/trident) implements the CSI specification for container orchestrators to manage the lifecycle of Amazon FSx for NetApp ONTAP file systems.

To improve security and reduce the amount of work, you can manage the Amazon FSx for NetApp ONTAP CSI driver as an Amazon EKS add-on. The IAM role needed by the add-on was created for us so we can go ahead and install the add-on:
```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name netapp_trident-operator \
  --configuration-values $'"cloudIdentity": "'eks.amazonaws.com/role-arn:$FSXN_CSI_ADDON_ROLE'"'
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name netapp_trident-operator
```

Now we can take a look at what has been created in our EKS cluster by the addon. For example, a DaemonSet will be running a pod on each node in our cluster:

```bash
$ kubectl get pods -n trident
NAME                                  READY   STATUS    RESTARTS   AGE
trident-controller-68f86749df-tr9nw   6/6     Running   0          25m
trident-node-linux-7wkg9              2/2     Running   0          25m
trident-node-linux-9g6w4              2/2     Running   0          25m
trident-node-linux-vpvnh              2/2     Running   0          25m
trident-operator-56fb7f67c4-vws4m     1/1     Running   0          29m
```

The FSx for NetApp ONTAP CSI driver supports dynamic and static provisioning. Currently dynamic provisioning creates an access point for each PersistentVolume. This mean an AWS EFS file system has to be created manually on AWS first and should be provided as an input to the StorageClass parameter. For static provisioning, AWS EFS file system needs to be created manually on AWS first. After that it can be mounted inside a container as a volume using the driver.

The workshop environment also has an FSx for NetApp ONTAP file system, Storage Virtual Machine (SVM) and the required security group pre-provisioned with an inbound rule that allows inbound NFS traffic for your Pods. You can retrieve information about the FSx for NetApp ONTAP file system by running the following AWS CLI command:

```bash
$ aws fsx describe-file-systems --file-system-id $FSXN_ID
```

Now, we'll need to create a TridentBackendConfig object configured to use the pre-provisioned FSx for NetApp ONTAP file system as part of this workshop infrastructure.

We'll be using Kustomize to create the backend and to ingest the environment variable `FSXN_IP` in the parameter`managementLIF` value in the configuration of the storage class object:

```file
manifests/modules/fundamentals/storage/fsxn/backend/fsxn-backend-nas.yaml
```

Let's apply this kustomization:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/backend \
  | envsubst | kubectl apply -f-
secret/backend-fsxn-ontap-nas-secret created
tridentbackendconfig.trident.netapp.io/backend-fsxn-ontap-nas created
```

Now we'll get check that the TridentBackendConfig was create using the below command:

```bash
$ kubectl get tbc -n trident
NAME                     BACKEND NAME          BACKEND UUID                           PHASE   STATUS
backend-fsxn-ontap-nas   backend-fsxn-ontap-   61a731e0-2f3c-4df9-9e49-5fc120e8247c   Bound   Success
```

Now, we'll need to create a StorageClass(https://kubernetes.io/docs/concepts/storage/storage-classes/) object

We'll be using Kustomize to create for the storage class:

```file
manifests/modules/fundamentals/storage/fsxn/storageclass/fsxnstorageclass.yaml
```

Let's apply this kustomization:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/storage/fsxn/storageclass/
storageclass.storage.k8s.io/fsxn-sc-nfs created
```

Now we'll get and describe the StorageClass using the below commands. Notice that the provisioner used is the `csi.trident.netapp.io` driver and the provisioning mode is `ontap-nas`.

```bash
$ kubectl get storageclass
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
fsxn-sc-nfs     csi.trident.netapp.io   Delete          Immediate              true                   44s

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
