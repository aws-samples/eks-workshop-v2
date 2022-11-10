---
title: "Persistence:Kubernetes/ContainerWithSensitiveMount"
sidebar_position: 132
---

```bash
$ kubectl apply -k /workspace/modules/security/Guardduty/privileged
```


```file
security/Guardduty/privileged/mount/previleged-pod-example.yaml
```


```bash
$ kubectl apply -k /workspace/modules/security/Guardduty/privileged/mount
```

```bash
$ kubectl delete -k /workspace/modules/security/Guardduty/privileged/mount
$ kubectl delete -k /workspace/modules/security/Guardduty/privileged
```