---
title: "Cleanup"
weight: 40
chapter: false
---

To delete all the resources in this chapter execute the commands below

```bash
# Cleanup K8S resources
kubectl delete deployment pause-pods
kubectl delete priorityclass default
kubectl delete priorityclass pause-pods

# Scale down application #TODO: Change after app
kubectl delete deployment nginx
```
