---
title: "CSIDrivers"
sidebar_position: 34
---

A [Container Storage Interface (CSI)](https://kubernetes.io/docs/concepts/storage/volumes/#csi) defines a standard interface for container orchestration systems (like Kubernetes) to expose arbitrary storage systems to their container workloads.

[Storage capacity](https://kubernetes.io/docs/concepts/storage/storage-capacity/) is limited and may vary depending on the node on which a pod runs: network-attached storage might not be accessible by all nodes, or storage is local to a node to begin with.