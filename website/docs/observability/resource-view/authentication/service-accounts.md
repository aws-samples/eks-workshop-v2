---
title: "ServiceAccounts"
sidebar_position: 40
---

A [ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) provides an identity for processes that run in a Pod. When you create a pod, if you do not specify a service account, it is automatically assigned the default service account in the same namespace. For example you can see the <i>spec.serviceAccountName</i> field has been automatically set in the [pod view](../workloads-view/pods_view)

![Insights](/img/resource-view/auth-resources.jpg)

To view additional details for a specific  <i>service account</i>, drill down to the namespace and click on the service account you want to view to see additional information such as <i>labels</i>, <i>annotations</i>, <i>events</i>. Below is the detail view for the <i>catalog</i> service account. 

![Insights](/img/resource-view/auth-sa-detail.jpg)
