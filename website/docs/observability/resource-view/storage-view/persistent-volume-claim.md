---
title: "PersistentVolumeClaims"
sidebar_position: 30
---

[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PVC) is a request for storage by a user. This resource is similar to Pods. Pods consume node resources and PVCs consume Persisten Volume (PV) resources. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes (e.g., they can be mounted ReadWriteOnce, ReadOnlyMany or ReadWriteMany. See [AccessModes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for more information)

Click on the PersistentVolumeClaim to drill down all the claims and select the _checkout_ namespace. 

![Insights](/img/resource-view/storage-pvclaim.jpg)

If you drill down to the namespace _checkout_ you can see the claims and select the respective claims to view the properties associated with it like storage, storage class, and volume mode.

![Insights](/img/resource-view/storage-pvclaim-detail2.jpg)
