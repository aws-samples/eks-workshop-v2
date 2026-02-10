---
title: "クラウドリソースのプロビジョニング"
sidebar_position: 6
tmdTranslationSourceHash: 17f0d5b57c14688e84d2e0e3989a323b
---

このセクションでは、カートが使用しているインメモリデータベースをDynamoDBに置き換えます。WebApplicationのベーステンプレートを拡張してWebApplicationDynamoDB ResourceGraphDefinitionを構成することで実現します。

まず、前のセクションで作成したkroインスタンスを削除しましょう：

```bash
$ kubectl delete webapplication.kro.run/carts -n carts
webapplication.kro.run "carts" deleted
```

これにより、関連するすべてのリソースがクリーンアップされます：

```bash
$ kubectl get all -n carts
No resources found in carts namespace.
```

次に、再利用可能なWebApplicationDynamoDB APIを定義するResourceGraphDefinitionテンプレートを確認しましょう：

<details>
  <summary>RGDマニフェストの全文を展開</summary>

::yaml{file="manifests/modules/automation/controlplanes/kro/rgds/webapp-dynamodb-rgd.yaml"}

</details>

このResourceGraphDefinitionは以下を行います：

1. WebApplication RGDを構成するカスタム`WebApplicationDynamoDB` APIを作成
2. ACKを使用してDynamoDBテーブルをプロビジョニング
3. DynamoDBアクセス用のIAMロールとポリシーを作成
4. アプリケーションPodからの安全なアクセスのためにEKS Pod Identityを設定

EKS Pod Identityの詳細については、[公式ドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)を参照してください。

:::info
このRGDのresourceセクションにWebApplication RGDが含まれていることに注目してください。`webApplication`を参照することで、このテンプレートはベースのWebApplication RGDで定義されたすべてのKubernetesリソースを再利用し、DynamoDB、IAM、およびPod Identityリソースを追加します。
:::

ResourceGraphDefinitionを適用してWebApplicationDynamoDB APIを登録しましょう：

```bash wait=10
$ kubectl apply -f ~/environment/eks-workshop/modules/automation/controlplanes/kro/rgds/webapp-dynamodb-rgd.yaml
resourcegraphdefinition.kro.run/web-application-ddb created
```

これによりWebApplicationDynamoDB APIが登録されます。Custom Resource Definition (CRD)を確認しましょう：

```bash
$ kubectl get crd webapplicationdynamodbs.kro.run
NAME                               CREATED AT
webapplicationdynamodbs.kro.run    2024-01-15T10:35:00Z
```

次に、WebApplicationDynamoDB APIを使用して**Carts**コンポーネントのインスタンスを作成するcarts-ddb.yamlファイルを確認しましょう：

::yaml{file="manifests/modules/automation/controlplanes/kro/app/carts-ddb.yaml" paths="kind,metadata,spec.appName,spec.replicas,spec.image,spec.port,spec.dynamodb,spec.env,spec.aws"}

1. RGDで作成されたカスタムWebApplicationDynamoDB APIを使用
2. `carts`名前空間に`carts`という名前のリソースを作成
3. リソース命名のためのアプリケーション名を指定
4. 1レプリカを設定
5. 小売店のカートサービスコンテナイメージを使用
6. ポート8080でアプリケーションを公開
7. DynamoDBテーブル名を指定
8. DynamoDB永続モードを有効にする環境変数を設定
9. IAMとPod Identityの設定のためにAWSアカウントIDとリージョンを提供

次に、carts-ddb.yamlファイルを活用して更新されたコンポーネントをデプロイしましょう：

```bash wait=10
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/kro/app \
  | envsubst | kubectl apply -f-
webapplicationdynamodb.kro.run/carts created
```

kroはこのカスタムリソースを処理し、DynamoDBテーブルを含むすべての基盤となるリソースを作成します。カスタムリソースが作成されたことを確認しましょう：

```bash
$ kubectl get webapplicationdynamodb -n carts
NAME    STATE         SYNCED   AGE
carts   IN_PROGRESS   False    16s
```

インスタンスが「同期された」状態に達するまで待機できます：

```bash
$ kubectl wait -o yaml webapplicationdynamodb/carts -n carts \
  --for=condition=InstanceSynced=True --timeout=120s
```

DynamoDBテーブルが作成されたことを確認するために、生成されたACKリソースをチェックできます：

```bash timeout=300
$ kubectl wait table.dynamodb.services.k8s.aws items -n carts --for=condition=ACK.ResourceSynced --timeout=15m
table.dynamodb.services.k8s.aws/items condition met
$ kubectl get table.dynamodb.services.k8s.aws items -n carts -ojson | yq '.status."tableStatus"'
ACTIVE
```

AWS CLIを使用してテーブルが作成されたことを確認しましょう：

```bash
$ aws dynamodb list-tables

{
    "TableNames": [
        "eks-workshop-carts-kro"
    ]
}
```

kroの組み合わせ可能なアプローチを使用して、DynamoDBテーブルとコンポーネントが正常に作成されました。

コンポーネントが新しいDynamoDBテーブルで正常に動作していることを確認するために、ブラウザを通じて操作することができます。テスト用にサンプルアプリケーションを公開するためのNLBが作成されています：

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com
```

:::info
このコマンドを実行すると、新しいNetwork Load Balancerエンドポイントがプロビジョニングされるため、実際のエンドポイントは異なります。
:::

ロードバランサーがプロビジョニングを完了したことを確認するには、次のコマンドを実行できます：

```bash timeout=610
curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

ロードバランサーがプロビジョニングされたら、ウェブブラウザにURLを貼り付けてアクセスできます。ウェブストアのUIが表示され、ユーザーとしてサイト内を移動できるようになります。

<Browser url="http://k8s-ui-ui-a9797f0f61.elb.us-west-2.amazonaws.com/">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

**Carts**モジュールが実際に先ほどプロビジョニングしたDynamoDBテーブルを使用していることを確認するために、カートにいくつかの商品を追加してみましょう。

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

これらの商品がDynamoDBテーブルにも存在することを確認するために、次のコマンドを実行します：

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-kro"
```

おめでとうございます！ベースのWebApplicationテンプレートを拡張してDynamoDBストレージを追加することで、kroの組み合わせ可能性を実証することに成功しました。
