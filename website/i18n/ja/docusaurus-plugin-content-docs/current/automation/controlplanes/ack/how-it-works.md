---
title: "ACKの仕組み"
sidebar_position: 5
tmdTranslationSourceHash: dab1dfb1b518410df47bf95ab800501e
---

:::info
kubectlは、フォーマットされた出力の代わりに、デプロイメント定義の完全なYAMLまたはJSON形式のマニフェストを抽出する便利な`-oyaml`や`-ojson`フラグも提供しています。
:::

このコントローラーは、`dynamodb.services.k8s.aws.Table`のようなDynamoDB特有のKubernetesカスタムリソースを監視します。これらのリソースの設定に基づいて、DynamoDBエンドポイントへのAPI呼び出しを行います。リソースが作成または変更されると、コントローラーは`Status`フィールドに値を設定してカスタムリソースのステータスを更新します。マニフェストの仕様に関する詳細は、[ACKリファレンスドキュメント](https://aws-controllers-k8s.github.io/community/reference/)を参照してください。

コントローラーが監視するオブジェクトとAPI呼び出しについてより深く理解するために、次のコマンドを実行できます：

```bash
$ kubectl get crd
```

このコマンドは、ACKやDynamoDBに関連するものを含め、クラスター内のすべてのカスタムリソース定義（CRD）を表示します。
