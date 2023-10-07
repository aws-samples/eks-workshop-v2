---
title: "Installing AWS Secrets and Configuration Provider (ASCP)"
sidebar_position: 62
---

If you ran the `prepare-environment` script detailed in the [previous step](index.md), it has already installed the AWS Secrets and Configuration Provider (ASCP) for the Kubernetes Secrets Store CSI Driver that's required for this lab.

Lets then, validate if the addons deployed.

Check the Secret Store CSI drive `DaemonSet` and respective `Pods`.

```bash
$ kubectl -n kube-system get daemonset -l "app=secrets-store-csi-driver"
NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
csi-secrets-store-provider-aws   1         1         1       1            1           kubernetes.io/os=linux   34s
```

```bash
$ kubectl -n kube-system get pods -l "app=secrets-store-csi-driver"
NAME                                               READY   STATUS    RESTARTS   AGE
csi-secrets-store-secrets-store-csi-driver-hd495   3/3     Running   0          39s
csi-secrets-store-secrets-store-csi-driver-hrqd7   3/3     Running   0          39s
```

Check the CSI Secrets Store Provider for AWS drive `DaemonSet` and respective `Pods`.

```bash
$ kubectl get daemonsets -n kube-system -l app=csi-secrets-store-provider-aws
NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
csi-secrets-store-provider-aws   2         2         2       2            2           kubernetes.io/os=linux   29s
```

```bash
$ kubectl get pods -n kube-system -l app=csi-secrets-store-provider-aws
NAME                                   READY   STATUS    RESTARTS   AGE
csi-secrets-store-provider-aws-jdxm2   1/1     Running   0          33s
csi-secrets-store-provider-aws-jjjmr   1/1     Running   0          33s
```
