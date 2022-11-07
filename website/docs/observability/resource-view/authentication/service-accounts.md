---
title: "ServiceAccounts"
sidebar_position: 40
---

A [ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) provides an identity for processes that run in a Pod. When you create a pod, if you do not specify a service account, it is automatically assigned the default service account in the same namespace. If you get the raw json or yaml for a pod you have created (for example, `kubectl get pods <i>podname</i> -o yaml`), you can see the <i>spec.serviceAccountName</i> field has been automatically set.

![Insights](/img/resource-view/auth-resources.jpg)

To view the detailed informations about <i>service accounts</i>, drill down to the namespace and click on the service account you want to view if there are any <i>labels</i>, <i>annotations</i>, <i>events</i>

![Insights](/img/resource-view/auth-sa-detail.jpg)