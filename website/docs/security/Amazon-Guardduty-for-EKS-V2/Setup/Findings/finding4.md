---
title: "Policy:Kubernetes/AdminAccessToDefaultServiceAccount"
sidebar_position: 129
---

The default service account in EKS Cluster was granted admin privileges. This may result in pods unintentionally launched with admin privileges. If this behavior is not expected, it may indicate a configuration mistake or that your credentials are compromised.

To simulate this we will need to bind clusterrole `cluster-admin` to a serviceaccount named `default`.

```bash
$ kubectl create rolebinding sa-default-admin --clusterrole=cluster-admin --serviceaccount=default:default --namespace=default
```

With in few minutes we will see the finding `Policy:Kubernetes/AdminAccessToDefaultServiceAccount` in guardduty portal. 

![](finding-2.png)

Run the following command to delete the role binding.

Cleanup: 
```bash
$ kubectl delete rolebinding sa-default-admin --namespace=default
```