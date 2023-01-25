---
title: "PersistentVolumes"
sidebar_position: 31
---

[PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) A PersistentVolume (PV) is a configured unit of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/). It's a resource in the cluster just like a node is a cluster resource. PVs are volume plugins like Volumes, but have a lifecycle independent of any individual Pod that uses the PV. This API object captures the details of the implementation of the storage, be that EBS, EFS or other third party PV providers.

![Insights](/img/resource-view/storage-pv.png)
