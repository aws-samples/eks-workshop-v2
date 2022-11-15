---
title: "Container With Sensitive Mount"
sidebar_position: 132
---

This finding indicates that a container was launched with a sensitive external host path mounted inside.

To simulate the finding we will be reusing Privileged Container manifest and patch it with host path volume mount.

Create the deployment by running the following command.

```bash
$ kubectl apply -k /workspace/modules/security/Guardduty/privileged
```

With in few minutes of applying the above deployment we will see the finding `PrivilegeEscalation:Kubernetes/PrivilegedContainer` in guardduty portal.

In order to simulate the Container With Sensitive Mount finding we will need to patch the above deployment with host path as shown in the following yaml.

```file
security/Guardduty/privileged/mount/previleged-pod-example.yaml
```

Patch the deployment by running the following command.

```bash
$ kubectl apply -k /workspace/modules/security/Guardduty/privileged/mount
```

With in few minutes we will see the finding `Persistence:Kubernetes/ContainerWithSensitiveMount` in guardduty portal.


Cleanup:

```bash
$ kubectl delete -k /workspace/modules/security/Guardduty/privileged/mount
$ kubectl delete -k /workspace/modules/security/Guardduty/privileged
```
