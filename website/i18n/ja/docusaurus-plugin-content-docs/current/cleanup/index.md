---
title: "クリーンアップ"
sidebar_position: 99
weight: 99
kiteTranslationSourceHash: e326c87fb0381c5b9a2e7b8bde3ec972
---

```bash timeout=900
$ prepare-environment
$ sleep 60
$ kubectl delete -k /eks-workshop/manifests/base-application --all || kubectl get all -A
$ sleep 60
```
