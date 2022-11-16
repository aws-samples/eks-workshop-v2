---
title: "Privileged Container"
sidebar_position: 131
---

This finding indicates that a privileged container with root level access was launched on your Kubernetes cluster.

To simulate the finding we will apply the following yaml.

```file
security/Guardduty/privileged/previleged-pod-example.yaml
```

Create the deployment by running the following command. Please note that the *environment* directory will be present in eks-workshop directory and the commands are executed from eks-workshop directory. eks-workshop directory must be downloaded prior to running below commands.

```bash
$ kubectl apply -k /workspace/modules/security/Guardduty/privileged/
```

With in few minutes we will see the finding `PrivilegeEscalation:Kubernetes/PrivilegedContainer` in guardduty portal.

![](PrivilegedContainer.png)

Cleanup:

```bash
$ kubectl delete -k /workspace/modules/security/Guardduty/privileged/
```
