---
title: "Cleanup"
sidebar_position: 99
weight: 99
---

```bash hookTimeout=600
$ prepare-environment
$ sleep 60
$ kubectl delete -k /eks-workshop/manifests/base-application --all
$ sleep 60
```
