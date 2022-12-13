---
title: "CSINodes"
sidebar_position: 35
---

Container Storage Interface (CSI) node plugins are needed to perform various privileged operations like scanning of disk devices and mounting of file systems. These operations differ for each host operating system. For Linux worker nodes, containerized CSI node plugins are typically deployed as privileged containers. For Windows worker nodes, privileged operations for containerized CSI node plugins is supported using [csi-proxy](https://github.com/kubernetes-csi/csi-proxy), a community-managed, stand-alone binary that needs to be pre-installed on each Windows node.

![Insights](/img/resource-view/storage-csinodes.png)

[CSI Storage capacity](https://kubernetes.io/docs/concepts/storage/storage-capacity/) is limited and may vary depending on the node on which a pod runs: network-attached storage might not be accessible by all nodes, or storage is local to a node to begin with.
