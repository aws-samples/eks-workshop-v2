---
title: "Cleanup"
sidebar_position: 90
---

Delete all the resources created in this module.

```bash
$ kubectl delete secret catalog-sealed-db -n catalog
$ kubectl delete sealedsecret catalog-sealed-db -n catalog
$ kubectl delete -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
```
