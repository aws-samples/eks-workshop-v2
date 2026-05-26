---
title: "AWS Secrets Managerでシークレットを管理する"
sidebar_position: 40
description: "Amazon Elastic Kubernetes Service上で実行されるアプリケーションに、AWS Secrets Managerを使用して認証情報などの機密設定を提供します。"
tmdTranslationSourceHash: '0f47d16061fcc1c6fcd6acb283a09b15'
---

:::tip セットアップ済みの内容
Amazon EKS Auto Modeクラスターには、以下のコンポーネントが設定されています。

- Kubernetes Secrets Store CSI Driver
- AWS Secrets and Configuration Provider
- External Secrets Operator
:::

[AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)は、認証情報、APIキー、証明書などの機密データを簡単にローテーション、管理、取得できるサービスです。[Kubernetes Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)と[AWS Secrets and Configuration Provider (ASCP)](https://github.com/aws/secrets-store-csi-driver-provider-aws)を使用することで、Secrets Managerに保存されたシークレットをKubernetes Podのボリュームとしてマウントできます。

ASCPにより、Amazon EKS上で実行されるワークロードは、IAMロールとポリシーを使用したきめ細かなアクセス制御を通じて、Secrets Managerに保存されたシークレットにアクセスできます。Podがシークレットへのアクセスをリクエストすると、ASCPはPodのIDを取得し、それをIAMロールと交換し、そのロールを引き受けてから、そのロールに許可されたシークレットのみをSecrets Managerから取得します。

AWS Secrets ManagerをKubernetesと統合する別のアプローチとして、[External Secrets](https://external-secrets.io/)があります。このオペレーターは、AWS Secrets ManagerからKubernetes Secretsへシークレットを同期し、抽象化レイヤーを通じてライフサイクル全体を管理します。Secrets ManagerからKubernetes Secretsへ値を自動的に注入します。

どちらのアプローチも、Secrets Managerを通じた自動シークレットローテーションをサポートしています。External Secretsを使用する場合は、更新をポーリングするリフレッシュ間隔を設定でき、Secrets Store CSI Driverはローテーションレコンサイラー機能を提供して、Podが常に最新のシークレット値を持つことを保証します。

以下のセクションでは、AWS Secrets ManagerとASCP、およびExternal Secretsの両方を使用してシークレットを管理する実践的な例を探ります。

