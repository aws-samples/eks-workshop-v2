---
title: "Admin Access To Default ServiceAccount"
sidebar_position: 129
---


In this lab exercise, we'll grant admin privileges to the Default `ServiceAccount`,  which may result in Pods unintentionally being launched with admin privileges. This is not a best practice because Pods get the token from the Default `ServiceAccount`. This will give unintentional Kubernetes administrative permissions to users who have `exec` access into Pods.

To simulate this we'll need to bind the `clusterrole` **cluster-admin** to a `ServiceAccount` named **default**.


```bash
$ kubectl create rolebinding sa-default-admin --clusterrole=cluster-admin --serviceaccount=default:default --namespace=default
```

Within a few minutes we'll see the finding `Policy:Kubernetes/AdminAccessToDefaultServiceAccount` in the GuardDuty portal.

![](policy_AdminAccessToDefaultServiceAccount.png)

Run the following command to delete the role binding.

```bash
$ kubectl delete rolebinding sa-default-admin --namespace=default
```
