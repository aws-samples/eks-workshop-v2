---
title: "アプリケーションの更新"
sidebar_position: 10
kiteTranslationSourceHash: 7785ef73c09264f95a4afeb8b2cb2c96
---

新しいリソースが作成または更新されると、アプリケーション設定はこれらの新しいリソースを利用するために調整する必要があることがよくあります。Kubernetesでは、環境変数は設定を保存するための一般的な選択肢であり、デプロイメントを作成する際に`container` [spec](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)の`env`フィールドを通じてコンテナに渡すことができます。

これを実現するための主な方法は2つあります：

1. **Configmaps**：これはKubernetesのコアリソースで、環境変数やテキストフィールド、その他のアイテムなどの設定要素をキーバリュー形式でポッドスペックに渡すことができます。

2. **Secrets**：これはConfigmapsに似ていますが、機密情報を扱うことを意図しています。Secretsはデフォルトでは暗号化されていないことに注意してください。

ACK `FieldExport` [カスタムリソース](https://aws-controllers-k8s.github.io/community/docs/user-docs/field-export/)は、ACKリソースのコントロールプレーンの管理と、それらのリソースの_プロパティ_をアプリケーションで使用することの間のギャップを埋めるように設計されています。ACKリソースから任意の`spec`または`status`フィールドをKubernetes ConfigMapまたはSecretにエクスポートするようにACKコントローラを設定します。これらのフィールドは、値が変更されると自動的に更新され、ConfigMapまたはSecretをKubernetesポッドに環境変数としてマウントできます。

このラボでは、カートコンポーネントのConfigMapを直接更新します。ローカルDynamoDBを指すように設定を削除し、ACKによって作成されたDynamoDBテーブルの名前を使用します：

```kustomization
modules/automation/controlplanes/ack/app/kustomization.yaml
ConfigMap/carts
```

また、カートPodにDynamoDBサービスにアクセスするための適切なIAM権限を提供する必要があります。IAMロールはすでに作成されており、IAM Roles for Service Accounts（IRSA）を使用してこれをカートPodsに適用します：

```kustomization
modules/automation/controlplanes/ack/app/carts-serviceAccount.yaml
ServiceAccount/carts
```

IRSAの仕組みについて詳しく知るには、[こちら](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)をご覧ください。

この新しい設定を適用しましょう：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/ack/app \
  | envsubst | kubectl apply -f-
```

新しいConfigMapの内容を取り込むためにcartsのPodsを再起動する必要があります：

```bash
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts --timeout=40s
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

アプリケーションが新しいDynamoDBテーブルで動作していることを確認するために、ブラウザを通じてそれと対話することができます。サンプルアプリケーションをテスト用に公開するためにNLBが作成されています：

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

:::info
このコマンドを実行すると、新しいネットワークロードバランサーエンドポイントがプロビジョニングされるため、実際のエンドポイントは異なります。
:::

ロードバランサーのプロビジョニングが完了するまで待つには、次のコマンドを実行できます：

```bash timeout=610
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

ロードバランサーがプロビジョニングされたら、URLをWebブラウザに貼り付けてアクセスできます。Webストアのユーザーインターフェイスが表示され、ユーザーとしてサイト内を移動することができます。

<Browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

**Carts**モジュールが確かに先ほどプロビジョニングしたDynamoDBテーブルを使用していることを確認するために、カートにいくつかのアイテムを追加してみてください。

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

これらのアイテムがDynamoDBテーブルにも存在することを確認するには、次のコマンドを実行します：

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-ack"
```

おめでとうございます！KubernetesのAPIを離れることなく、AWSリソースの作成に成功しました！

