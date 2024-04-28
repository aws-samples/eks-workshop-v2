---
title: "Authorization"
sidebar_position: 100
---

In EKS, you must be <i>authenticated</i> (logged in) before your request can be <i>authorized</i> (granted permission to access). Kubernetes expects attributes that are common to REST API requests. This means that EKS authorization works with [AWS Identity and Access Management](https://docs.aws.amazon.com/eks/latest/userguide/security-iam.html) for access control.

In this lab, we'll view Kubernetes **Role Based Access Control (RBAC)** resources: Cluster Roles, Roles, ClusterRoleBindings and RoleBindings. RBAC is the process of providing restricted least privileged access to EKS clusters and its objects as per the IAM roles mapped to the EKS cluster users. Following diagram depicts how the access control flows when users or service accounts try to access the objects in EKS cluster through the Kubernetes client and API's.

:::info
Check out the [Security](../../../security/) module for additional examples.
:::

![Insights](/img/resource-view/autz-index.jpg)
