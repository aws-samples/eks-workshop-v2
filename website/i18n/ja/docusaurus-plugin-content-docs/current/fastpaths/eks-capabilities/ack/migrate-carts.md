---
title: "carts サービスの移行"
sidebar_position: 30
tmdTranslationSourceHash: 6924d091e1ce06a092bf4693df43147d
---

DynamoDB テーブルは存在していますが、`carts` Deployment はまだクラスター内の `carts-dynamodb` Pod を参照しています。AWS テーブルに切り替えるには、2つの変更が必要です:

1. **ConfigMap:** `RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT` を置き換え、`_CREATE_TABLE` フラグを削除します（テーブルは既に存在しています）。
2. **EKS Pod Identity:** `carts` ServiceAccount を事前にプロビジョニングされた IAM role にバインドして、Pod が DynamoDB を呼び出せるようにします。このロールとそのポリシーは `prepare-environment` 中に作成されます。ServiceAccount に関連付けるだけです。

ConfigMap にパッチを適用する kustomization を確認してください:

```kustomization
modules/fastpaths/eks-capabilities/ack/carts/kustomization.yaml
ConfigMap/carts
```

:::note
ベースアプリケーションのローカル `carts-dynamodb` Pod と Service はそのまま残ります。アプリケーションのデータベースへのポインタを切り替えるだけで、クリーンアップによって元の ConfigMap が復元されるため、他のラボも正常に動作します。
:::

kustomization を適用します:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/ack/carts \
  | envsubst | kubectl apply -f -
```

[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) を介して、`carts` ServiceAccount を IAM role にバインドします。ロール `${EKS_CLUSTER_AUTO_NAME}-carts-dynamo` は `prepare-environment` によって作成されており、既に `-carts` と `-carts-fastpath` の両方のテーブルへのアクセス権を持っています:

```bash wait=30
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_AUTO_NAME}-carts-dynamo \
  --namespace carts --service-account carts | jq .
```

新しい ConfigMap と Pod Identity バインディングを取得するために、`carts` Pod を再起動します:

```bash timeout=120
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=90s
deployment "carts" successfully rolled out
```

Pod が新しいテーブル名を認識し、Pod Identity 認証情報が利用可能であることを確認します:

```bash
$ kubectl exec -n carts deployment/carts -- env \
  | grep -E '^RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME='
RETAIL_CART_PERSISTENCE_DYNAMODB_TABLE_NAME=...-carts-fastpath
```

```bash
$ kubectl exec -n carts deployment/carts -- env \
  | grep AWS_CONTAINER_CREDENTIALS_FULL_URI
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://...
```

`AWS_CONTAINER_CREDENTIALS_FULL_URI` 環境変数が存在することで、Pod Identity が IAM role を Pod に配線していることが確認できます。carts サービスが行うすべての DynamoDB 呼び出しは、プロビジョニングしたテーブルのみにスコープされたロールの認証情報を使用します。

これで ACK ラボは完了です。小売アプリは現在、Kubernetes API から EKS capability によって完全にプロビジョニングおよび調整された、実際の AWS マネージド DynamoDB テーブルによってサポートされています。

次に、**Argo CD capability** を使用して GitOps で `catalog` サービスを配信します。

