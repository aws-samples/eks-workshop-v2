---
title: "PersistentVolumeClaims"
sidebar_position: 30
---

[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PVC) is a request for storage by a user. It is similar to a Pod. Pods consume node resources and PVCs consume PV resources. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes (e.g., they can be mounted ReadWriteOnce, ReadOnlyMany or ReadWriteMany, , see [AccessModes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes))

Click on the PersistentVolumeClaim to drill down all the claims by filtering to the respective namespaces on right side panel

![Insights](/img/resource-view/storage-pvclaim.jpg)

If you drill down to the namespaces <i>checkout</i> you can see the claims and select the respective claims to identify the properties associated with it like storage, storage class, volume mode

![Insights](/img/resource-view/storage-pvclaim-detail2.jpg)
