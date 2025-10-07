---
title: "EKSコンソールを表示"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Serviceコンソールでのクラスターリソースの可視性を獲得する。"
kiteTranslationSourceHash: 92d2125af80b7f62d4fa9165aa0849a4
---

::required-time

:::tip 始める前に
このセクションのために環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment
```

:::

このラボでは、AWS Management ConsoleのAmazon EKSを使用して、すべてのKubernetes APIリソースタイプを表示します。設定、認証リソース、ポリシーリソース、サービスリソースなどの標準的なすべてのKubernetes APIリソースタイプを表示および探索することができます。[Kubernetesリソースビュー](https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html)は、Amazon EKSがホストするすべてのKubernetesクラスターでサポートされています。[Amazon EKS Connector](https://docs.aws.amazon.com/eks/latest/userguide/eks-connector.html)を使用して、適合するKubernetesクラスターをAWSに登録および接続し、Amazon EKSコンソールで可視化することができます。

サンプルアプリケーションによって作成されたリソースを表示します。環境の準備中に作成された[RBACアクセス権限](https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html#view-kubernetes-resources-permissions)を持つリソースのみが表示されることに注意してください。

![インサイト](/img/resource-view/eks-overview.jpg)

