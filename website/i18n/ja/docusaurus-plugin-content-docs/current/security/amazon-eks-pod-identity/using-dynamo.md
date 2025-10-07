---
title: "Amazon DynamoDB の使用"
sidebar_position: 32
kiteTranslationSourceHash: 513c401e03117c6fbba61dec1d1d081f
---

このプロセスの最初のステップは、carts サービスを再設定して、すでに作成されている DynamoDB テーブルを使用することです。アプリケーションは、ほとんどの設定を ConfigMap から読み込んでいます。確認してみましょう：

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

また、ブラウザを使用してアプリケーションの現在のステータスを確認してください。`ui` 名前空間に `LoadBalancer` タイプのサービス `ui-nlb` がプロビジョニングされており、このサービスからアプリケーションの UI にアクセスできます。

```bash
$ kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}'
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

上記のコマンドで生成された URL を使用して、ブラウザで UI を開きます。以下のように Retail Store が表示されるはずです。

![ホーム](/img/sample-app-screens/home.webp)

以下の kustomization は ConfigMap を上書きし、DynamoDB エンドポイント設定を削除します。これにより、SDK はテスト用の Pod ではなく実際の DynamoDB サービスを使用するように指示されます。また、すでに作成されている DynamoDB テーブル名も設定しています。テーブル名は環境変数 `RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME` から取得されています。

```kustomization
modules/security/eks-pod-identity/dynamo/kustomization.yaml
ConfigMap/carts
```

`CARTS_DYNAMODB_TABLENAME` の値を確認し、Kustomize を実行して実際の DynamoDB サービスを使用するように設定しましょう：

```bash
$ echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/security/eks-pod-identity/dynamo \
  | envsubst | kubectl apply -f-
```

これにより、ConfigMap が新しい値で上書きされます：

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

次に、新しい ConfigMap の内容を反映させるために、すべての carts Pod を再起動する必要があります：

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

変更の適用に失敗したようです。Pod を確認して確認してみましょう：

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

何が問題なのでしょうか？

