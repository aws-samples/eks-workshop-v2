---
title: "高度なトラブルシューティング"
sidebar_position: 23
tmdTranslationSourceHash: '6c4206e0e9598d5d32a6a550378ac804'
---

このセクションでは、Kiro CLI と [MCP server for Amazon EKS](https://awslabs.github.io/mcp/servers/eks-mcp-server/) を使用して、Kubernetes、EKS、その他の AWS サービスに関する知識がなければ解決が困難な、EKS クラスター内の複雑な問題をトラブルシューティングします。

まず、作成済みの DynamoDB テーブルを使用するように carts サービスを再設定します。アプリケーションは、ほとんどの設定を ConfigMap から読み込みます。現在の ConfigMap を確認してみましょう:

```bash
$ kubectl -n carts get -o yaml cm carts
apiVersion: v1
data:
  AWS_ACCESS_KEY_ID: key
  AWS_SECRET_ACCESS_KEY: secret
  RETAIL_CART_PERSISTENCE_DYNAMODB_CREATE_TABLE: "true"
  RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT: http://carts-dynamodb:8000
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: Items
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  name: carts
  namespace: carts
```

次の kustomization を使用して ConfigMap を更新します。これにより DynamoDB エンドポイントの設定が削除され、SDK がテスト Pod の代わりに実際の DynamoDB サービスを使用するように指示されます。また、環境変数 `RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME` に、すでに作成されている DynamoDB テーブル名を設定しました:

```kustomization
modules/aiml/kiro-cli/troubleshoot/dynamo/kustomization.yaml
ConfigMap/carts
```

DynamoDB テーブル名を確認して、新しい設定を適用しましょう:

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/kiro-cli/troubleshoot/dynamo \
  | envsubst | kubectl apply -f-
```

更新された ConfigMap を確認します:

```bash
$ kubectl -n carts get cm carts -o yaml
apiVersion: v1
data:
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: eks-workshop-carts
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  labels:
    app: carts
  name: carts
  namespace: carts
```

`RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME` 属性が、この EKS クラスター内のテーブルではなく、アカウント内の実際の DynamoDB テーブルを指していることがわかります。

:::tip
`DynamodDB > Tables` メニューからコンソールを使用して、アカウント内のこの DynamoDB テーブルを確認できます。
:::

それでは、新しい ConfigMap の内容を反映するために carts deployment を再デプロイしましょう:

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

デプロイメントが失敗したようです。Pod のステータスを確認してみましょう:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

この問題を調査するために Kiro CLI を使用してみましょう。新しい Kiro CLI セッションを開始します:

```bash test=false
$ kiro-cli chat
```

Kiro CLI に問題のトラブルシューティングを依頼します:

```text
I have a pod in my eks-workshop cluster that is with status CrashLoopBackOff. Troubleshoot the issue and resolve it for me.
```

このプロンプトに対処するために、Kiro CLI は MCP server からさまざまなツールを使用します。前の例で見たツールに加えて、次のようなことも行う可能性があります:

1. EKS MCP server の `get_policies_for_role` ツールを使用してスコープ内の IAM role とポリシーを記述する
2. Kiro CLI に組み込まれている `use_aws` ツールを使用して AWS リソースに関する詳細情報を取得する
3. 問題を解決するための是正措置を講じる

この問題を解決するために Kiro CLI が提供する提案に従ってください。理想的なシナリオでは、問題は修正されるはずです。最後に、Kiro CLI は実行した手順の最終ステータス概要を提示します。

<details>
  <summary>サンプルレスポンスを展開する</summary>

```text
  The issue is resolved. Here's a summary:
  
  Root Cause: The carts pod (carts-6956bbbbf6-9lsd6) was crashing because it couldn't access DynamoDB. The pod's service account had no IRSA role configured, so it fell back to the node instance role (eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-nH1a0rWkr5Um), which lacked DynamoDB permissions.
  
  Fix Applied: Added an inline IAM policy CartsDynamoDBAccess to the node instance role granting the necessary DynamoDB actions (Query, Scan, GetItem, PutItem, UpdateItem, DeleteItem, DescribeTable, BatchGetItem, BatchWriteItem) on the eks-workshop-auto-carts table and its indexes.
  
  Result: The replacement pod carts-6956bbbbf6-2qsbw is now Running and Ready with zero restarts.

▸ Credits: 1.94 • Time: 3m 43s
```

</details>

完了したら、次のコマンドを入力して Kiro CLI セッションを終了します。

```text
/quit
```

最後に、Pod が正しく実行されていることを確認します:

```bash test=false
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS   AGE
carts-596b6f94df-q4449            1/1     Running   0          9m5s
carts-dynamodb-698fcb695f-zvzf5   1/1     Running   0          2d1h
```

これで Kiro CLI の紹介は終了です。この強力なツールが、EKS 用の MCP server と組み合わせることで、EKS クラスター内の複雑な問題の診断と解決にどのように役立つかを見てきました。

