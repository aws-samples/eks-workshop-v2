---
title: "高度なトラブルシューティング"
sidebar_position: 23
tmdTranslationSourceHash: b2128fa90940138d820b4fbf911c468c
---

このセクションでは、Amazon Q CLIと[Amazon EKS用のMCPサーバー](https://awslabs.github.io/mcp/servers/eks-mcp-server/)を使用して、Kubernetes、EKS、その他のAWSサービスの知識がなければ解決が困難なEKSクラスターの複雑な問題をトラブルシューティングします。

まず、カートサービスを、私たちのために作成されたDynamoDBテーブルを使用するように再構成しましょう。アプリケーションは設定のほとんどをConfigMapからロードします。現在のConfigMapを確認してみましょう：

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

ConfigMapを更新するために、以下のkustomizationを使用します。これはDynamoDBエンドポイント設定を削除し、テストPodの代わりに実際のDynamoDBサービスを使用するようにSDKに指示します。また、環境変数`RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME`でDynamoDBテーブル名を設定しています：

```kustomization
modules/aiml/q-cli/troubleshoot/dynamo/kustomization.yaml
ConfigMap/carts
```

DynamoDBテーブル名を確認して、新しい設定を適用しましょう：

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/aiml/q-cli/troubleshoot/dynamo \
  | envsubst | kubectl apply -f-
```

更新されたConfigMapを確認します：

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

では、新しいConfigMapの内容を反映させるためにcartsデプロイメントを再デプロイしましょう：

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

デプロイメントが失敗したようです。Podのステータスを確認してみましょう：

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

Amazon Q CLIを使用して、この問題を調査しましょう。新しいQ CLIセッションを開始します：

```bash test=false
$ q chat
```

Q CLIに問題のトラブルシューティングを依頼します：

```text
I have a pod in my eks-workshop cluster that is with status CrashLoopBackOff. Troubleshoot the issue and resolve it for me.
```

この要求に対応するために、Q CLIはMCPサーバーからさまざまなツールを使用します。前の例で見たツールに加えて、次のようなツールも使用する可能性があります：

1. `get_policies_for_role`ツールを使用して、スコープ内のIAMロールとポリシーを記述する
2. Q CLIに組み込まれている`use_aws`ツールを使用して、AWSリソースに関連する追加情報を取得する
3. 問題を解決するために修正アクションを実行する

Q CLIが提案する解決策に従って、この問題を解決しましょう。理想的なシナリオでは、問題が修正されるはずです。最後に、Q CLIは実行した手順の最終ステータスの概要を表示します。

<details>
  <summary>サンプルレスポンスを展開する</summary>

```text
Perfect! The CrashLoopBackOff issue has been successfully resolved. Here's a summary of what I found and fixed:

## Problem Analysis

The pod carts-d49c67c77-k2zvz in the carts namespace was in CrashLoopBackOff state with:
• **Restart count:** 9 restarts
• **Exit code:** 1 (error)
• **Root cause:** DynamoDB permissions issue

## Root Cause

The application logs showed this error:
User: arn:aws:sts::1234567890:assumed-role/eks-workshop-carts-dynamo/eks-eks-worksh-carts-d49c-c1857ccc-86be-4bd6-9c6d-0b90748341b4 is not authorized to perform: dynamodb:Query on resource: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/idx_global_customerId because no identity-based policy allows the dynamodb:Query action


The IAM role eks-workshop-carts-dynamo had a policy that granted access to a table named wrong-table-name, but the application was trying to access eks-workshop-carts.

## Solution Applied

1. Identified the correct DynamoDB table: eks-workshop-carts
2. Added proper IAM permissions: Created an inline policy CartsTableAccess with the following permissions:
   • Actions: dynamodb:GetItem, PutItem, UpdateItem, DeleteItem, Query, Scan, BatchGetItem, BatchWriteItem
   • Resources: arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts and its indexes
3. Restarted the pod: Deleted the failing pod to allow the deployment to create a new one with the updated permissions

## Result

The new pod carts-d49c67c77-mks7h is now:
• **Status:** Running and Ready
• **Restart count:** 0
• **Application:** Successfully started and connected to DynamoDB
• **Health checks:** Passing (both liveness and readiness probes)

The CrashLoopBackOff issue has been completely resolved, and the carts service is now functioning properly with correct DynamoDB access permissions.
```

</details>

終了したら、以下のコマンドを入力してQ CLIセッションを終了します。

```text
/quit
```

最後に、Podが正常に実行されていることを確認します：

```bash test=false
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS   AGE
carts-596b6f94df-q4449            1/1     Running   0          9m5s
carts-dynamodb-698fcb695f-zvzf5   1/1     Running   0          2d1h
```

これでAmazon Q CLIの紹介を終了します。この強力なツールが、EKS用のMCPサーバーと組み合わせることで、EKSクラスターの複雑な問題を診断し解決するのにどのように役立つかを確認しました。
