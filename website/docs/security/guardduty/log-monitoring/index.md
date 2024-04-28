---
title: "EKS Log Monitoring"
sidebar_position: 520
---

EKS Audit Log Monitoring when enabled, immediately begins to monitor Kubernetes audit logs from your clusters and analyze them to detect potentially malicious and suspicious activity. It consumes Kubernetes audit log events directly from the Amazon EKS control plane logging feature through an independent stream of flow logs.

In this lab exercise, we'll generate a few Kubernetes audit monitoring findings in your Amazon EKS cluster, listed below.

- `Execution:Kubernetes/ExecInKubeSystemPod`
- `Discovery:Kubernetes/SuccessfulAnonymousAccess`
- `Policy:Kubernetes/AnonymousAccessGranted`
- `Impact:Kubernetes/SuccessfulAnonymousAccess`
- `Policy:Kubernetes/AdminAccessToDefaultServiceAccount`
- `Policy:Kubernetes/ExposedDashboard`
- `PrivilegeEscalation:Kubernetes/PrivilegedContainer`
- `Persistence:Kubernetes/ContainerWithSensitiveMount`
