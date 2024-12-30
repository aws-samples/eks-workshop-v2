---
title: "Cleanup"
sidebar_position: 99
weight: 99
---

```bash timeout=900
$ prepare-environment
$ sleep 60
$ kubectl delete -k /eks-workshop/manifests/base-application --all || kubectl get all -A
$ sleep 60
```
