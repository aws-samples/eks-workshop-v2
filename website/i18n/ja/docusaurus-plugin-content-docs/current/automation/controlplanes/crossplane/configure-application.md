---
title: "アプリケーションの更新"
sidebar_position: 25
kiteTranslationSourceHash: 9fc4419f2ed8a6c543ef6ff5f14ad1dd
---

新しいリソースが作成または更新されると、アプリケーション設定はこれらの新しいリソースを利用するように調整する必要があることがよくあります。環境変数はアプリケーション開発者が設定を保存するために人気のある選択肢であり、Kubernetesでは、デプロイメントを作成する際に`container` [仕様](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)の`env`フィールドを通じてコンテナに環境変数を渡すことができます。

Kubernetesでこれを実現するための主な方法は2つあります：

1. **ConfigMap**：これらはKubernetesのコアリソースであり、環境変数、テキストフィールド、その他のアイテムをキーと値の形式でポッド仕様で使用するように渡すことができます。
2. **Secret**：デフォルトでは暗号化されていませんが（これは覚えておくことが重要です）、シークレットはパスワードなどの機密情報を保存するために使用されます。

このラボでは、cartsコンポーネントのConfigMapの更新に焦点を当てます。ローカルのDynamoDBを指す設定を削除し、代わりにCrossplaneによって作成されたDynamoDBテーブルの名前を使用します：

```kustomization
modules/automation/controlplanes/crossplane/app/kustomization.yaml
ConfigMap/carts
```

さらに、cartsポッドにDynamoDBサービスにアクセスするための適切なIAM権限を提供する必要があります。IAMロールはすでに作成されており、IAM Roles for Service Accounts（IRSA）を使用してこれをcartsポッドに適用します：

```kustomization
modules/automation/controlplanes/crossplane/app/carts-serviceAccount.yaml
ServiceAccount/carts
```

IRSAの仕組みについて詳しく学ぶには、[公式ドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)を参照してください。

この新しい設定を適用しましょう：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/app \
  | envsubst | kubectl apply -f-
```

新しいConfigMapの内容を取得するために、すべてのcartsポッドをリサイクルする必要があります：

```bash
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=40s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

アプリケーションが新しいDynamoDBテーブルで動作していることを確認するために、サンプルアプリケーションを公開するために作成されたNetwork Load Balancer（NLB）を使用できます。これにより、Webブラウザを通じてアプリケーションと直接対話することができます：

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

:::info
このコマンドを実行すると、新しいNetwork Load Balancerエンドポイントがプロビジョニングされるため、実際のエンドポイントは異なります。
:::

ロードバランサーがプロビジョニングを完了するまで待つには、次のコマンドを実行します：

```bash timeout=610
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

ロードバランサーがプロビジョニングされたら、WebブラウザにURLを貼り付けてアクセスできます。Webストアのユーザーインターフェイスが表示され、サイト内をユーザーとして移動することができます。

<Browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

**Carts**モジュールが実際に私たちがプロビジョニングしたDynamoDBテーブルを使用していることを確認するには、カートにいくつかのアイテムを追加してみてください。

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

DynamoDBテーブルにもアイテムが存在するかどうかを確認するには、次のコマンドを実行します：

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-crossplane"
```

おめでとうございます！KubernetesのAPI内から離れることなく、AWSリソースを正常に作成して利用しました！
