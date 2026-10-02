---
title: "CartsStack インスタンスの適用"
sidebar_position: 30
tmdTranslationSourceHash: 'e3158a728e0a600ccded19f9281b6aab'
---

## Pod Identity アソシエーションの事前バインド

Pod Identity は EKS API であり、Kubernetes のものではないため、RGD 内に存在できません。最初にアソシエーションを作成します（EKS はまだ存在しない ServiceAccount のバインドを許可します）。これにより、carts Pod は既に認証情報が配線された状態で起動します。ロールは ACK ラボの同じワイルドカードスコープの `-carts-dynamo` ロールなので、kro テーブルは既にカバーされています：

```bash wait=10
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_AUTO_NAME}-carts-dynamo \
  --namespace carts-kro --service-account carts | jq '.association.associationId'
"a-..."
```

## CartsStack インスタンスの適用

インスタンスマニフェストは小さいです：

```yaml
apiVersion: kro.run/v1alpha1
kind: CartsStack
metadata:
  name: carts-kro
  namespace: default
spec:
  tableName: ${EKS_CLUSTER_AUTO_NAME}-carts-kro
  namespace: carts-kro
```

適用します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/kro/instance \
  | envsubst | kubectl apply -f -
cartsstack.kro.run/carts-kro created
```

:::tip
[ACK ラボ](../ack/migrate-carts.md)と比較してください：同じ最終状態を得るために、3つの別々の `kubectl apply` ステップと `aws eks create-pod-identity-association` 呼び出し、そして `kubectl rollout restart` が必要でした。ここでは、1つの `CartsStack` リソースがグラフ全体を駆動し、プラットフォームチームは carts 形状のスタックを必要とする全員のために RGD を一度だけ記述します。
:::

kro は依存関係の順序で6つの子リソースを調整します：最初に `Namespace` を作成し、次に `Table`（ACK DynamoDB コントローラーが AWS でのプロビジョニングを開始します）を作成し、Namespace が存在したら `ConfigMap` と `ServiceAccount` を作成し、最後に SA と ConfigMap が参照されたら `Deployment` と `Service` を作成します。carts Pod は、前のステップで作成した Pod Identity アソシエーションによって既に注入された IAM 認証情報で起動します。

インスタンスが `ACTIVE` に達するまで待ちます：

```bash timeout=720
$ kubectl wait cartsstack carts-kro --for=jsonpath='{.status.state}'=ACTIVE --timeout=10m
cartsstack.kro.run/carts-kro condition met
```

:::note
これには数分かかる場合があります。インスタンスは、すべての子が正常になって初めて `ACTIVE` を報告します。最も遅い子は、AWS で作成されている実際の DynamoDB テーブルです。
:::

## kro が作成したものを検査する

インスタンスが `ACTIVE` に達したため、kro は既にすべての子を作成し、ヘルスチェックを完了しています。新しい Namespace でそれらをリストして、1回の適用からのグラフ全体を確認します：

```bash
$ kubectl -n carts-kro get table,configmap,serviceaccount,deployment,service
NAME                                    SYNCED   AGE
table.dynamodb.services.k8s.aws/items   True     ...

NAME                     DATA   AGE
configmap/carts          2      ...
configmap/kube-root-ca.crt   1  ...

NAME                   SECRETS   AGE
serviceaccount/carts   0         ...
serviceaccount/default 0         ...

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/carts   1/1     1            1           ...

NAME            TYPE        CLUSTER-IP   PORT(S)   AGE
service/carts   ClusterIP   ...          80/TCP    ...
```

`Table` は `SYNCED=True` を表示しており、ACK コントローラーが実際の AWS テーブルの作成を完了したことを意味します。AWS 側に存在することを確認します：

```bash
$ aws dynamodb describe-table \
  --table-name "$EKS_CAP_DDB_TABLE_KRO" \
  --query 'Table.TableStatus' --output text
ACTIVE
```

1つの `CartsStack` 適用により、実際の AWS DynamoDB テーブルに加えて、Kubernetes リソースの完全な Namespace が生成され、kro が順序とヘルスチェックを処理してくれました。

## Pod が DynamoDB に到達できることを検証する

carts Pod には、ServiceAccount、新しいテーブルを指す ConfigMap、Pod Identity による IAM 認証情報、DynamoDB へのネットワークパスがあります。Deployment が完全にロールアウトされるまで待ち（Amazon EKS Auto Mode がまだ Pod のノードをスケーリングしている可能性があります）、Pod Identity が Pod 起動時にロールの認証情報を注入したことを確認します：

```bash timeout=180
$ kubectl rollout status -n carts-kro deployment/carts --timeout=150s
deployment "carts" successfully rolled out
$ kubectl exec -n carts-kro deployment/carts -- env \
  | grep AWS_CONTAINER_CREDENTIALS_FULL_URI
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://...
```

`AWS_CONTAINER_CREDENTIALS_FULL_URI` 環境変数が存在することは、Pod がスケジュールされたときに Pod Identity がロールの認証情報を注入したことを確認します。Pod は次の経路で AWS DynamoDB テーブルに接続されます：

- **ServiceAccount** → `aws eks create-pod-identity-association`
- → **IAM role `${EKS_CLUSTER_AUTO_NAME}-carts-dynamo`**
- → **AWS DynamoDB table `${EKS_CLUSTER_AUTO_NAME}-carts-kro`**

これで kro ラボは完了です。ACK とネイティブの Kubernetes リソースを単一のリソースに構成する高レベルの Kubernetes API（`CartsStack`）を定義し、単一のインスタンスが完全で実行中の IAM バインドされた carts サービスを生成しました。

## オプション：小売ストア UI で kro ラボの carts を確認する

デフォルトでは、小売ストアの `ui` Pod は `carts.carts.svc` と通信します。これは ACK ラボの Namespace です（ベース UI ConfigMap の `RETAIL_UI_ENDPOINTS_CARTS` で設定されています）。同じ変数を `carts-kro` の kro 管理 carts サービスに再指定し、UI を再起動します：

```bash test=false
$ kubectl -n ui set env deployment/ui RETAIL_UI_ENDPOINTS_CARTS=http://carts.carts-kro:80
$ kubectl -n ui rollout status deployment/ui --timeout=60s
deployment "ui" successfully rolled out
```

Ingress で UI を公開します。Amazon EKS Auto Mode には AWS Load Balancer Controller が含まれているため、`Ingress` を適用すると、パブリック Application Load Balancer が自動的にプロビジョニングされます：

```bash test=false
$ envsubst < ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/ui-ingress/ingressclass.yaml \
  | kubectl apply -f -
$ kubectl apply -f ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/ui-ingress/ingress.yaml
```

ロードバランサーのプロビジョニングが完了するまで待ち（これには数分かかります）、その URL を出力します：

```bash test=false
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 \
  --connect-timeout 30 --max-time 60 -k -s -o /dev/null \
  $(kubectl get ingress -n ui ui-auto -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://$(kubectl get ingress -n ui ui-auto -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')"
http://k8s-ui-uiauto-....us-west-2.elb.amazonaws.com
```

その URL をブラウザで開きます。ALB はドメインルートでアプリを提供するため、**Explore** を含むストア全体をナビゲートできます。いくつかのアイテムをカートに追加すると、kro 管理の `${EKS_CLUSTER_AUTO_NAME}-carts-kro` DynamoDB テーブルに保存されます：

```bash test=false
$ aws dynamodb scan --table-name "$EKS_CAP_DDB_TABLE_KRO" \
  --query 'Count' --output text
```

完了したら、Ingress を削除し、UI を ACK ラボの carts Namespace に戻します：

```bash test=false
$ kubectl delete -n ui ingress ui-auto --ignore-not-found
$ kubectl -n ui set env deployment/ui RETAIL_UI_ENDPOINTS_CARTS=http://carts.carts.svc:80
$ kubectl -n ui rollout status deployment/ui --timeout=60s
```

