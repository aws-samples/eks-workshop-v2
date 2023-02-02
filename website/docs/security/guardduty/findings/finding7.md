---
title: "Container With Sensitive Mount"
sidebar_position: 132
---

This finding indicates that a container was launched with a sensitive external host path mounted inside.

To simulate the finding we'll be reusing Privileged Container manifest and patch it with host path volume mount. Let's apply the patched version of privileged container from earlier example with host path `/etc` mounted to container's path `/test-pd`.

```file
security/Guardduty/mount/privileged-pod-example.yaml
```

Run the below command to patch the deployment.

```bash
$ kubectl apply -f /workspace/modules/security/Guardduty/mount/privileged-pod-example.yaml
```

Within a few minutes we'll see the finding `Persistence:Kubernetes/ContainerWithSensitiveMount` in the GuardDuty portal.

![](ContainerWithSensitiveMount.png)

Cleanup:

```bash
$ kubectl delete -f /workspace/modules/security/Guardduty/privileged/mount/privileged-pod-example.yaml
```
