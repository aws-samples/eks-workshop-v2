---
title: "Clean Up"
date: 2022-06-09T00:00:00-03:00
weight: 6
---

### Cleaning up

To delete the resources used in this chapter

```bash
kubectl taint nodes $FIRST_NODE_NAME dedicated=team1:NoSchedule-
unset FIRST_NODE_NAME
kubectl delete -f podlife-nginx.yaml
kubectl delete deployment nginx
```
