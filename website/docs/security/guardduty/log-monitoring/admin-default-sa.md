---
title: "Admin access to default Service Account"
sidebar_position: 522
---

In this next lab exercise, we'll grant cluster administrative privileges to a Service Account. This is not a best practice because may result in Pods using this Service Account being unintentionally launched with administrative permissions, allowing users that have `exec` access to these Pods, to escalate and gain unrestricted access to the cluster.

To simulate this we'll need to bind the `cluster-admin` Cluster Role the `default` Service Account in the `default` Namespace.

```bash
$ kubectl -n default create rolebinding sa-default-admin --clusterrole cluster-admin --serviceaccount default:default
```

Within a few minutes you'll see the finding `Policy:Kubernetes/AdminAccessToDefaultServiceAccount` in the [GuardDuty Findings console](https://console.aws.amazon.com/guardduty/home#/findings). Take sometime to analyze the Finding details, Action, and Detective Investigation.

![Admin access finding](assets/admin-access-sa.webp)

Delete the offending Role Binding by running the following command.

```bash
$ kubectl -n default delete rolebinding sa-default-admin
```
