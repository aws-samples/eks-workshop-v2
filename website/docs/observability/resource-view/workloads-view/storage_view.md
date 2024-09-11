---
title: "Storage"
sidebar_position: 40
---

To view the Kubernetes storage resources, click on the <i>Resources</i> tab. Drill down to the <i>Storage</i> section and you can view several the Kubernetes API resource types related to storage that are part of cluster including:

- Persistent Volume Claims
- Persistent Volumes
- Storage Classes
- Volume Attachments
- CSI Drivers
- CSI Nodes

The [Storage](../../../fundamentals/storage/) workshop module goes into more details on how to configure and use storage for stateful workloads.

[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PVC) is a request for storage by a user. This resource is similar to Pods. Pods consume node resources and PVCs consume Persistent Volume (PV) resources. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes (e.g., they can be mounted ReadWriteOnce, ReadOnlyMany or ReadWriteMany. See [AccessModes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for more information)

[PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) A PersistentVolume (PV) is a configured unit of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/). It's a resource in the cluster just like a node is a cluster resource. PVs are volume plugins like Volumes, but have a lifecycle independent of any individual Pod that uses the PV. This API object captures the details of the implementation of the storage, be that EBS, EFS or other third party PV providers.

[StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) provides a way for administrators to describe the "classes" of storage that are available to a cluster. Different classes might map to quality-of-service levels, or to backup policies, or to arbitrary policies determined by cluster administrators.

[VolumeAttachment](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/volume-attachment-v1/) captures the intent to attach or detach the specified volume to/from the specified node.

[Container Storage Interface (CSI)](https://kubernetes.io/docs/concepts/storage/volumes/#csi) defines a standard interface for Kubernetes to expose arbitrary storage systems to container workloads.
Container Storage Interface (CSI) node plugins are needed to perform various privileged operations like scanning of disk devices and mounting of file systems. These operations differ for each host operating system. For Linux worker nodes, containerized CSI node plugins are typically deployed as privileged containers. For Windows worker nodes, privileged operations for containerized CSI node plugins is supported using [csi-proxy](https://github.com/kubernetes-csi/csi-proxy), a community-managed, stand-alone binary that needs to be pre-installed on each Windows node.
