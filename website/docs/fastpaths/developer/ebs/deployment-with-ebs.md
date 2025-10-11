---
title: Using persistent EBS volumes
sidebar_position: 20
---

Now let's update the catalog MySQL database to use persistent EBS storage. With EKS Auto Mode, the EBS CSI Driver is already installed and managed by AWS.

## Create the StorageClass

The StorageClass defines how EKS Auto Mode will provision EBS volumes. While EKS Auto Mode includes the EBS CSI Driver, you need to create a StorageClass that references `ebs.csi.eks.amazonaws.com` to use the storage capability.

::yaml{file="manifests/modules/fastpath/developers/ebs/storageclass.yaml" paths="provisioner,parameters.type"}

1. `provisioner: ebs.csi.eks.amazonaws.com` - Uses EKS Auto Mode's built-in EBS CSI Driver
2. `type: gp3` - Specifies the EBS volume type

Apply the StorageClass:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/fastpath/developers/ebs/storageclass.yaml
```

## Update the catalog MySQL database

Since many StatefulSet fields, including `volumeClaimTemplates`, cannot be modified, we'll need to delete and recreate the catalog service with the new storage configuration.

First, delete the current catalog MySQL StatefulSet:

```bash
$ kubectl delete -n catalog statefulset catalog-mysql
```

Now recreate it with persistent storage enabled. The updated StatefulSet includes a `volumeClaimTemplates` section:

::yaml{file="manifests/modules/fastpath/developers/ebs/statefulset-mysql.yaml" paths="spec.volumeClaimTemplates.0.spec.storageClassName,spec.volumeClaimTemplates.0.spec.accessModes,spec.volumeClaimTemplates.0.spec.resources"}

1. The `storageClassName` specifies the ebs-sc StorageClass for dynamic provisioning
2. The `accessModes` specifies ReadWriteOnce, allowing the volume to be mounted by a single node
3. We are requesting a 30GB EBS volume

Apply the configuration:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fastpath/developers/ebs
```

## Verify the PersistentVolumeClaim

The recreated catalog MySQL StatefulSet now has an associated PersistentVolumeClaim.

```bash
$ kubectl describe statefulset -n catalog catalog-mysql
Name:               catalog-mysql
Namespace:          catalog
...
  Containers:
   mysql:
    Image:      public.ecr.aws/docker/library/mysql:8.0
    Port:       3306/TCP
    Mounts:
      /var/lib/mysql from data (rw)
Volume Claims:
  Name:          data
  StorageClass:  
  Labels:        <none>
  Annotations:   <none>
  Capacity:      30Gi
  Access Modes:  [ReadWriteOnce]
```

List all PVCs:

```bash
$ kubectl get pvc -n catalog
NAME                   STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   AGE
data-catalog-mysql-0   Bound    pvc-abc123...   30Gi       RWO            ebs-sc         2m
```

Inspect the PVC details:

```bash
$ kubectl describe pvc -n catalog data-catalog-mysql-0
Name:          data-catalog-mysql-0
Namespace:     catalog
StorageClass:  ebs-sc
Status:        Bound
Volume:        pvc-abc123...
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: ebs.csi.aws.com
Capacity:      30Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Used By:       catalog-mysql-0
```

The PVC is bound to a PV, provisioned using **ebs.csi.aws.com** with 30Gi capacity.

## Inspect the PersistentVolume

```bash
$ kubectl describe pv $(kubectl get pvc -n catalog data-catalog-mysql-0 -o jsonpath="{.spec.volumeName}")
Name:              pvc-abc123...
Annotations:       pv.kubernetes.io/provisioned-by: ebs.csi.aws.com
StorageClass:      ebs-sc
Status:            Bound
Claim:             catalog/data-catalog-mysql-0
Reclaim Policy:    Delete
Access Modes:      RWO
VolumeMode:        Filesystem
Capacity:          30Gi
Node Affinity:
  Required Terms:
    Term 0:        topology.kubernetes.io/zone in [us-west-2a]
Source:
    Type:       CSI (a Container Storage Interface (CSI) volume source)
    Driver:     ebs.csi.aws.com
    FSType:     ext4
    VolumeHandle: vol-0abc123...
    ReadOnly:   false
```

The **VolumeHandle** references the Amazon EBS Volume ID. The **Node Affinity** ensures the pod is scheduled in the same Availability Zone as the EBS volume.

## Verify the EBS volume

Get the EBS Volume ID:

```bash
$ MYSQL_PV_NAME=$(kubectl get pvc -n catalog data-catalog-mysql-0 -o jsonpath="{.spec.volumeName}")
$ MYSQL_EBS_VOL_ID=$(kubectl get pv $MYSQL_PV_NAME -o jsonpath="{.spec.csi.volumeHandle}")
$ echo "EBS Volume ID: $MYSQL_EBS_VOL_ID"
```

Display the EBS volume details:

```bash
$ aws ec2 describe-volumes --volume-ids $MYSQL_EBS_VOL_ID
```

The volume uses gp3 storage with encryption enabled.

## Test data persistence

Let's verify that data persists across pod restarts. Create a test file in the MySQL data directory:

```bash
$ kubectl exec -n catalog catalog-mysql-0 -- bash -c "echo 123 > /var/lib/mysql/test.txt"
```

Verify the test file was created:

```bash
$ kubectl exec -n catalog catalog-mysql-0 -- ls -larth /var/lib/mysql/ | grep -i test
-rw-r--r--. 1 root  root     4 Oct 11 00:39 test.txt
```

Now delete the pod to simulate a failure:

```bash
$ kubectl delete pod -n catalog catalog-mysql-0
```

Wait for the StatefulSet controller to automatically recreate the pod:

```bash
$ kubectl wait --for=condition=Ready -n catalog pod/catalog-mysql-0 --timeout=120s
```

Verify the test file still exists after the pod restart:

```bash
$ kubectl exec -n catalog catalog-mysql-0 -- cat /var/lib/mysql/test.txt
123
```

Success! The test file persisted across the pod restart because it's stored on the EBS volume, not in the pod's ephemeral storage. Amazon EBS is storing the data and keeping it safe and available within an AWS availability zone.

## Summary

In this section, we:

- Updated the catalog MySQL database to use persistent EBS storage
- Verified that the EBS volume was created correctly
- Tested data persistence across pod restarts

With EKS Auto Mode, the EBS CSI Driver is pre-installed and managed, making it simple to provision persistent block storage for your stateful workloads.
