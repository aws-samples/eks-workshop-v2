---
title: FSx for Lustre CSI Driver
sidebar_position: 20
---

Before diving into this section, you should be familiar with the Kubernetes storage objects (volumes, persistent volumes (PV), persistent volume claims (PVC), dynamic provisioning and ephemeral storage) that were introduced in the main [Storage](../index.md) section.

The [Amazon FSx for Lustre Container Storage Interface (CSI) Driver](https://github.com/kubernetes-sigs/aws-fsx-csi-driver) provides a CSI interface that allows Amazon EKS clusters to manage the lifecycle of Amazon FSx for Lustre file systems. This enables you to run stateful containerized applications that require high-performance parallel file storage.

The following architecture diagram illustrates how we will use FSx for Lustre as persistent storage for our EKS pods:

![Assets with FSx for Lustre](/docs/fundamentals/storage/fsx-for-lustre/fsxl-storage.webp)

To utilize Amazon FSx for Lustre with dynamic provisioning on our EKS cluster, we need to install the FSx for Lustre CSI Driver. The driver implements the CSI specification which allows container orchestrators to manage Amazon FSx for Lustre file systems throughout their lifecycle.

As part of the lab preparation, an IAM role has already been created for the CSI driver to call the appropriate AWS APIs.

We'll install the FSx for Lustre CSI driver as an EKS add-on:

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME \
    --addon-name aws-fsx-csi-driver \
    --service-account-role-arn $FSXL_IAM_ROLE \
    --resolve-conflicts OVERWRITE
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME \
    --addon-name aws-fsx-csi-driver
```

Let's verify the driver is running in our EKS cluster:

```bash
$ kubectl get daemonset fsx-csi-node -n kube-system
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
fsx-csi-node   3         3         3       3            3           kubernetes.io/os=linux   52s
```

The FSx for Lustre CSI driver supports dynamic provisioning, which allows you to create an FSx for Lustre file system on demand. When a PersistentVolumeClaim (PVC) is created, the driver automatically provisions a new FSx for Lustre file system and binds it to the PVC.

An FSx for Lustre file system has been pre-provisioned for us as part of the lab setup, along with the required security group that allows Lustre traffic. Let's get its ID which we'll need later:

```bash
$ echo $FSXL_FS_ID
fs-0123456789abcdef0
```

We also need the DNS name and mount name of the file system for our StorageClass:

```bash
$ export FSXL_DNS_NAME=$(aws fsx describe-file-systems --file-system-ids $FSXL_FS_ID --query "FileSystems[0].DNSName" --output text)
$ export FSXL_MOUNT_NAME=$(aws fsx describe-file-systems --file-system-ids $FSXL_FS_ID --query "FileSystems[0].LustreConfiguration.MountName" --output text)
$ echo "DNS Name: $FSXL_DNS_NAME"
$ echo "Mount Name: $FSXL_MOUNT_NAME"
```

Next, we'll create a [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) that uses static provisioning with our pre-created FSx for Lustre file system.

Let's examine the `fsxlstorageclass.yaml` file:

::yaml{file="manifests/modules/fundamentals/storage/fsxl/storageclass/fsxlstorageclass.yaml" paths="provisioner,parameters.subnetId,parameters.securityGroupIds"}

1. Set the `provisioner` parameter to `fsx.csi.aws.com` for the FSx for Lustre CSI provisioner
2. Assign the subnet ID where the file system resides
3. Assign the security group ID for Lustre traffic

Apply the kustomization:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxl/storageclass \
  | envsubst | kubectl apply -f-
storageclass.storage.k8s.io/fsx-lustre-sc created
```

Let's examine the StorageClass:

```bash
$ kubectl get storageclass fsx-lustre-sc
NAME            PROVISIONER     RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
fsx-lustre-sc   fsx.csi.aws.com   Delete          Immediate           false                  10s
```

Now we'll also create a PersistentVolume and PersistentVolumeClaim that reference our pre-provisioned FSx for Lustre file system:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fundamentals/storage/fsxl/pv \
  | envsubst | kubectl apply -f-
persistentvolume/fsxl-pv created
persistentvolumeclaim/fsxl-claim created
```

Let's verify the PVC is bound:

```bash
$ kubectl get pvc -n ui fsxl-claim
NAME         STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS    AGE
fsxl-claim   Bound    fsxl-pv   1200Gi     RWX            fsx-lustre-sc   10s
```

Now that we understand the FSx for Lustre StorageClass and how the FSx for Lustre CSI driver works, we're ready to proceed to the next step where we'll modify the UI component to use the FSx for Lustre volume for storing product images.
