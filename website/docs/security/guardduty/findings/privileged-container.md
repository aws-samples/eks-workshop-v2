---
title: "Privileged container"
sidebar_position: 134
---

This finding indicates that a privileged container with root level access was launched on your Kubernetes cluster.

To simulate the finding we'll apply the following yaml.

```file
manifests/modules/security/Guardduty/privileged/privileged-pod-example.yaml
```

Create the deployment by running the following command.

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/Guardduty/privileged/privileged-pod-example.yaml
```

Within a few minutes we'll see the finding `PrivilegeEscalation:Kubernetes/PrivilegedContainer` in the GuardDuty portal.

![](assets/PrivilegedContainer.png)

Lets delete this pod before we move on:

```bash
$ kubectl delete -f ~/environment/eks-workshop/modules/security/Guardduty/privileged/privileged-pod-example.yaml
```
