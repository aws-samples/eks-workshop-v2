---
title: "DynamoDB テーブルのプロビジョニング"
sidebar_position: 20
tmdTranslationSourceHash: '6b3f4b1bafaba45aa5208202574b9c12'
---

実際の DynamoDB テーブルを Kubernetes リソースとして定義できるようになりました。マニフェストを見てみましょう:

::yaml{file="manifests/modules/fastpaths/eks-capabilities/ack/dynamodb/table.yaml" paths="kind,spec.tableName,spec.billingMode,spec.keySchema,spec.globalSecondaryIndexes"}

1. ACK DynamoDB コントローラーの `Table` カスタムリソースを使用します。
2. 並行したワークショップの実行が衝突しないように、クラスター名 (`${EKS_CLUSTER_AUTO_NAME}-carts-fastpath`) に基づいてテーブルに名前を付けます。
3. オンデマンド料金を使用します。
4. `carts` サービスが期待するものに一致する、パーティションキーのスキーマを定義します。
5. サービスが顧客ごとにカートをクエリできるように、`customerId` に global secondary index を追加します。

:::info
この YAML は [DynamoDB `CreateTable` API](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_CreateTable.html) を密接に反映しています。API を通じて表現できるものは、ここでも表現できます。
:::

マニフェストを適用します:

```bash wait=10
$ kubectl kustomize ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/ack/dynamodb \
  | envsubst | kubectl apply -f -
table.dynamodb.services.k8s.aws/items created
```

Capability の DynamoDB コントローラーは、新しい `Table` リソースを検出し、対応する AWS リソースをプロビジョニングします。`ACK.ResourceSynced` condition を待ちます。これは、すべての ACK リソースが正常に調整されたことを示す方法です:

```bash timeout=720
$ kubectl wait table.dynamodb.services.k8s.aws items \
  -n carts --for=condition=ACK.ResourceSynced --timeout=10m
table.dynamodb.services.k8s.aws/items condition met
```

リソースのステータスを確認します:

```bash
$ kubectl get table.dynamodb.services.k8s.aws items -n carts \
  -o jsonpath='{.status.tableStatus}{"\n"}'
ACTIVE
```

最後に、テーブルが AWS に存在することを確認します:

```bash
$ aws dynamodb describe-table \
  --table-name "$EKS_CAP_DDB_TABLE" \
  --query 'Table.TableStatus' --output text
ACTIVE
```

Kubernetes API から離れることなく、実際の DynamoDB テーブルを作成しました。Capability は、コントローラーのインフラストラクチャと DynamoDB API を呼び出すために必要な IAM パーミッションの両方を処理しました。

