---
title: "AWS Secrets Managerを使用したシークレット管理"
sidebar_position: 420
sidebar_custom_props: { "module": true }
description: "AWS Secrets Managerを使用して、Amazon Elastic Kubernetes Serviceで実行されるアプリケーションに認証情報などの機密設定を提供します。"
tmdTranslationSourceHash: c8dc2ea96764fae14ed1aee14eef493c
---

::required-time

:::tip 始める前に
このセクションの環境を準備します：

```bash timeout=600 wait=30 hook=install
$ prepare-environment security/secrets-manager
```

これにより、ラボ環境に以下の変更が適用されます：

以下のKubernetesアドオンがEKSクラスタにインストールされます：

- Kubernetes Secrets Store CSIドライバー
- AWS Secrets and Configuration Provider
- External Secrets Operator

これらの変更を適用するTerraformは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/secrets-manager/.workshop/terraform)で確認できます。
:::

[AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)は、認証情報、APIキー、証明書などの機密データを簡単にローテーション、管理、取得できるサービスです。[AWS Secrets and Configuration Provider (ASCP)](https://github.com/aws/secrets-store-csi-driver-provider-aws)と[Kubernetes Secrets Store CSIドライバー](https://secrets-store-csi-driver.sigs.k8s.io/)を使用することで、Secrets Managerに保存されているシークレットをKubernetesポッドにボリュームとしてマウントできます。

ASCPを使用すると、Amazon EKSで実行されているワークロードは、IAMロールとポリシーを使用した細かいアクセス制御を通じて、Secrets Managerに保存されているシークレットにアクセスできます。ポッドがシークレットへのアクセスを要求すると、ASCPはポッドのIDを取得し、それをIAMロールと交換し、そのロールを引き受け、Secrets Managerから認可されたシークレットのみを取得します。

AWS Secrets ManagerとKubernetesを統合するもう一つの方法は[External Secrets](https://external-secrets.io/)を使用することです。このオペレーターは、AWS Secrets ManagerからKubernetesのSecretへシークレットを同期し、抽象化レイヤーを通じてライフサイクル全体を管理します。これは自動的にSecrets Managerの値をKubernetesのSecretに注入します。

どちらのアプローチもSecrets Managerを通じた自動シークレットローテーションをサポートしています。External Secretsを使用する場合は、更新をポーリングするためのリフレッシュ間隔を設定でき、Secrets Store CSIドライバーは常に最新のシークレット値をポッドに提供するためのローテーション調整機能を提供します。

以下のセクションでは、AWS Secrets ManagerをASCPおよびExternal Secretsと共に使用したシークレット管理の実践的な例を見ていきます。
