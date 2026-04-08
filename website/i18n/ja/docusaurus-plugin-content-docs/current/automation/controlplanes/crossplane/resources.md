---
title: "Managed Resources"
sidebar_position: 20
tmdTranslationSourceHash: b87b841cd6de246ccbdc2b50c39813bf
---

デフォルトでは、サンプルアプリケーションの**Carts**コンポーネントは、EKSクラスタ内でポッドとして実行されている`carts-dynamodb`という名前のDynamoDB localインスタンスを使用しています。このラボのセクションでは、Crossplaneマネージドリソースを使用してアプリケーション用のAmazon DynamoDBクラウドベースのテーブルをプロビジョニングし、**Carts**デプロイメントを設定して、ローカルコピーの代わりに新しくプロビジョニングされたDynamoDBテーブルを使用するようにします。

![Crossplane reconciler concept](/docs/automation/controlplanes/crossplane/Crossplane-desired-current-ddb.webp)

Crossplaneマネージドリソースマニフェストを使用してDynamoDBテーブルを作成する方法を見てみましょう：

::yaml{file="manifests/modules/automation/controlplanes/crossplane/managed/table.yaml" paths="apiVersion,kind,metadata,spec.forProvider.attribute,spec.forProvider.hashKey,spec.forProvider.billingMode,spec.forProvider.globalSecondaryIndex,spec.providerConfigRef"}

1. Upboundの AWS DynamoDB プロバイダーを使用
2. DynamoDB テーブルリソースを作成
3. クラスタ接頭辞付きの名前と外部名アノテーションを持つKubernetesオブジェクトを指定
4. `id`と`customerId`を文字列（`S`）タイプの属性として定義
5. `id`をプライマリパーティションキーとして設定
6. オンデマンド価格モデルを指定
7. `customerId`にグローバルセカンダリインデックスを作成し、すべての属性をプロジェクション
8. 認証のためのAWSプロバイダー設定を参照

では、`dynamodb.aws.upbound.io`リソースを使用してDynamoDBテーブルの設定を作成しましょう。

```bash wait=10 timeout=400 hook=table
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/managed \
  | envsubst | kubectl apply -f-
table.dynamodb.aws.upbound.io/eks-workshop-carts-crossplane created
$ kubectl wait tables.dynamodb.aws.upbound.io ${EKS_CLUSTER_NAME}-carts-crossplane \
  --for=condition=Ready --timeout=5m
```

AWSマネージドサービスのプロビジョニングには時間がかかります。DynamoDBの場合、最大2分かかることがあります。Crossplaneは、Kubernetesカスタムリソースの`status`フィールドに調整の状態を報告します。

```bash
$ kubectl get tables.dynamodb.aws.upbound.io
NAME                                        READY  SYNCED   EXTERNAL-NAME                   AGE
eks-workshop-carts-crossplane               True   True     eks-workshop-carts-crossplane   6s
```

この設定を適用すると、CrossplaneはAWSにDynamoDBテーブルを作成し、アプリケーションで使用できるようになります。次のセクションでは、アプリケーションを更新して、この新しく作成されたテーブルを使用するようにします。
