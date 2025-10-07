---
title: "Managed Resources"
sidebar_position: 20
kiteTranslationSourceHash: e81d15132f922d1b0a8726eea8a68b82
---

デフォルトでは、サンプルアプリケーションの**Carts**コンポーネントは、EKSクラスタ内でポッドとして実行されている`carts-dynamodb`という名前のDynamoDBローカルインスタンスを使用しています。このラボのセクションでは、Crossplaneマネージドリソースを使用してアプリケーション用のAmazon DynamoDBクラウドベースのテーブルをプロビジョニングし、**Carts**デプロイメントを設定して、ローカルコピーの代わりに新しくプロビジョニングされたDynamoDBテーブルを使用するようにします。

![Crossplane reconciler concept](./assets/Crossplane-desired-current-ddb.webp)

Crossplaneマネージドリソースマニフェストを使用してDynamoDBテーブルを作成する方法を見てみましょう：

```file
manifests/modules/automation/controlplanes/crossplane/managed/table.yaml
```

次に、`dynamodb.aws.upbound.io`リソースを使用してDynamoDBテーブルの設定を作成できます。

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
