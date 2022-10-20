---
title: "Cleanup"
sidebar_position: 90
---

Delete all the resources created in this module.

```bash
$ kubectl delete secret --all -n secure-secrets
$ kubectl delete sealedsecret --all -n secure-secrets
$ kubectl delete pod --all -n secure-secrets
$ kubectl delete -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
$ kubectl delete namespace secure-secrets
```