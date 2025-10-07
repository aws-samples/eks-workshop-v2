---
title: "DynamoDBの使用"
sidebar_position: 22
kiteTranslationSourceHash: f432af3be771b49e4e4aea89fde6edf4
---

このプロセスの最初のステップは、`carts`サービスを再設定して、すでに作成されているDynamoDBテーブルを使用することです。アプリケーションは設定情報のほとんどをConfigMapから読み込みます。確認してみましょう：

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

以下のkustomizationは、ConfigMapを上書きし、DynamoDBエンドポイントの設定を削除することで、SDKがテストPodではなく実際のDynamoDBサービスをデフォルトで使用するようにします。また、環境変数`RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME`から取得された、すでに作成されているDynamoDBテーブルの名前も提供しています。

```kustomization
modules/security/irsa/dynamo/kustomization.yaml
ConfigMap/carts
```

`CARTS_DYNAMODB_TABLENAME`の値を確認し、Kustomizeを実行して実際のDynamoDBサービスを使用しましょう：

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/security/irsa/dynamo \
  | envsubst | kubectl apply -f-
```

これにより、ConfigMapが新しい値で上書きされます：

```bash
$ kubectl get -n carts cm carts -o yaml
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

次に、新しいConfigMapの内容を取り込むために、すべてのcarts Podをリサイクルする必要があります：

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

変更のデプロイに失敗したようです。Podを確認することでこれを確認できます：

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

何が問題になっているのでしょうか？
