---
title: "Persistence:Kubernetes/ContainerWithSensitiveMount"
sidebar_position: 131
---

```kustomization
security/Guardduty/privileged/deployment.yaml
Deployment/carts
```

```bash
$ kubectl apply -k /workspace/modules/security/privileged
```

```bash
$ kubectl delete -k /workspace/modules/security/privileged
```