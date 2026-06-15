---
title: "Amazon DynamoDB の使用"
sidebar_position: 32
tmdTranslationSourceHash: '8a2dad5af76103e706512f44167f1dda'
---

このプロセスの最初のステップは、既に作成されている DynamoDB テーブルを使用するように carts サービスを再設定することです。アプリケーションはほとんどの設定を ConfigMap から読み込みます。それを見てみましょう：

```bash
$ kubectl -n carts get -o yaml cm carts | yq
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

次の kustomization は ConfigMap を上書きして、DynamoDB エンドポイントの設定を削除します。これにより、SDK はテスト用の Pod の代わりに実際の DynamoDB サービスを使用するように指示されます。また、既に作成されている DynamoDB テーブル名も設定しました。テーブル名は環境変数 `RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME` から取得されています。

```kustomization
modules/security/eks-pod-identity/dynamo/kustomization.yaml
ConfigMap/carts
```

DynamoDB テーブル名を設定し、Kustomize を実行して実際の DynamoDB サービスを使用しましょう：

```bash
$ export CARTS_DYNAMODB_TABLENAME=${EKS_CLUSTER_AUTO_NAME}-carts && echo $CARTS_DYNAMODB_TABLENAME
eks-workshop-auto-carts
$ kubectl kustomize ~/environment/eks-workshop/modules/security/eks-pod-identity/dynamo \
  | envsubst | kubectl apply -f-
```

これにより、ConfigMap が新しい値で上書きされます：

```bash
$ kubectl -n carts get cm carts -o yaml | yq
apiVersion: v1
data:
  AWS_REGION: us-west-2
  RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME: eks-workshop-auto-carts
  RETAIL_CART_PERSISTENCE_PROVIDER: dynamodb
kind: ConfigMap
metadata:
  labels:
    app: carts
  name: carts
  namespace: carts
```

次に、新しい ConfigMap の内容を取得するために、すべての carts Pod を再起動する必要があります：

```bash expectError=true hook=enable-dynamo
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=20s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

変更が適切にデプロイされなかったようです。Pod を確認することでこれを確認できます：

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS             RESTARTS        AGE
carts-5d486d7cf7-8qxf9            1/1     Running            0               5m49s
carts-df76875ff-7jkhr             0/1     CrashLoopBackOff   3 (36s ago)     2m2s
carts-dynamodb-698674dcc6-hw2bg   1/1     Running            0               20m
```

何が問題だったのでしょうか？

