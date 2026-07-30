---
title: "ACKの仕組み"
sidebar_position: 5
tmdTranslationSourceHash: dab1dfb1b518410df47bf95ab800501e
---

:::info
kubectlは、フォーマットされた出力の代わりに、デプロイメント定義の完全なYAMLまたはJSON形式のマニフェストを抽出する便利な`-oyaml`や`-ojson`フラグも提供しています。
:::

AWS マネージドインフラストラクチャ上で実行されるマネージド ACK コントローラーは、`dynamodb.services.k8s.aws.Table` のような DynamoDB 固有の Kubernetes カスタムリソースを監視します。これらのリソースの設定に基づいて、DynamoDB エンドポイントへの API 呼び出しを行います。リソースが作成または変更されると、コントローラーは `Status` フィールドに値を設定してカスタムリソースのステータスを更新します。マニフェストの仕様に関する詳細は、[ACK リファレンスドキュメント](https://aws-controllers-k8s.github.io/community/reference/)を参照してください。

ACK がクラスター内で利用可能にしているリソースタイプを確認するには、次のコマンドを実行します：

```bash
$ kubectl get crd
```

このコマンドは、クラスター内のすべてのカスタムリソース定義（CRD）を表示します。`*.services.k8s.aws` のリソースがいくつも一覧に表示されることに注目してください。マネージド ACK ケイパビリティは、DynamoDB だけでなく、幅広い AWS サービス（S3、RDS、IAM など）の CRD をインストールします。

これは、セルフマネージドの ACK 構成との重要な違いです。セルフマネージドでは、サービスごとに個別のコントローラー（たとえば DynamoDB コントローラー単体）をインストールするため、そのサービスの CRD のみがクラスターで利用可能になります。マネージド ACK ケイパビリティでは、Amazon EKS が単一のマネージドケイパビリティを通じて幅広い ACK 対応サービスの CRD を利用可能にします。そのため、サービスごとにコントローラーをインストールして運用することなく、Kubernetes から多数の AWS サービスを管理できます。
