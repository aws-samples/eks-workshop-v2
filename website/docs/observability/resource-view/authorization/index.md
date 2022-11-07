---
title: "Authorization"
sidebar_position: 100
---

In Kubernetes, you must be <i>authenticated</i> (logged in) before your request can be <i>authorized</i> (granted permission to access). Kubernetes expects attributes that are common to REST API requests. This means that Kubernetes authorization works with existing organization-wide or cloud-provider-wide access control systems which may handle other APIs besides the Kubernetes API. 

In this module, we will learn about using **Role Based Access Control (RBAC)**. RBAC is the process of providing restricted or least priviliged access to EKS clusters and its objects as per the iam roles mapped to the EKS cluster users.Following diagram depicts how the access control flows when users or service accounts try to access the objects in EKS cluster through kubernetes client and API's. Refer to _[kubernetes-io docs](https://kubernetes.io/docs/concepts/security/controlling-access/)_ to go over some of the examples for the access control flow.

![Insights](/img/resource-view/autz-index.jpg)



