---
title: "EKS Log Monitoring"
sidebar_position: 520
tmdTranslationSourceHash: f8634397e9ee0acf471865e8045d50db
---

EKS監査ログモニタリングを有効にすると、クラスターのKubernetes監査ログを直ちにモニタリングし、潜在的に悪意のある不審なアクティビティを検出するために分析を開始します。Amazon EKSコントロールプレーンのロギング機能から、フローログの独立したストリームを通じて、Kubernetes監査ログイベントを直接消費します。

このラボ演習では、Amazon EKSクラスターで以下のいくつかのKubernetes監査モニタリングの検出結果を生成します。

- `Execution:Kubernetes/ExecInKubeSystemPod`
- `Discovery:Kubernetes/SuccessfulAnonymousAccess`
- `Policy:Kubernetes/AnonymousAccessGranted`
- `Impact:Kubernetes/SuccessfulAnonymousAccess`
- `Policy:Kubernetes/AdminAccessToDefaultServiceAccount`
- `Policy:Kubernetes/ExposedDashboard`
- `PrivilegeEscalation:Kubernetes/PrivilegedContainer`
- `Persistence:Kubernetes/ContainerWithSensitiveMount`
