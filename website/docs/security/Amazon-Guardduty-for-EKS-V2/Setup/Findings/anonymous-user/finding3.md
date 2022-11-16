---
title: "Anonymous Access Granted to k8's API'"
sidebar_position: 126
---

This finding indicates that the anonymous user `system:anonymous` was granted API permissions on the EKS cluster. This enables unauthenticated access to the permitted APIs.

To simulate this we will create a role **pod-create** in default namespace.

```bash
$ kubectl create role pod-create --verb=get,list,watch,create,delete,patch --resource=pods -n default
```

Once the cluster role is created we will bind the role with `system:anonymous` user. Below command will create rolebinding named pod-access binding role pod-create to the user named system:anonymous.

```bash
$ kubectl create rolebinding pod-access --role=pod-create --user=system:anonymous
```

With in few minutes we will see the finding `Policy:Kubernetes/AnonymousAccessGranted` in guardduty portal.

![](Policy_AnonymousAccessGranted.png)

Cleanup:

```bash
$ kubectl delete rolebinding pod-access -n default
$ kubectl delete role pod-create -n default
```
