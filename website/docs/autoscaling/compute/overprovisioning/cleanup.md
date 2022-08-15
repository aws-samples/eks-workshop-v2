---
title: "Clean Up"
sidebar_position: 50
---

This module requires some manual cleanup due to the nature of the changes we made to our cluster. To make sure subsequent content runs correctly lets tidy up the cluster.

```bash wait=10
kubectl delete deployment pause-pods && \
kubectl delete priorityclass default && \
kubectl delete priorityclass pause-pods && \
kubectl delete deployment nginx
```