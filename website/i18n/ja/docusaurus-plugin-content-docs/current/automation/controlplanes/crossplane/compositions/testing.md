---
title: "アプリケーションのテスト"
sidebar_position: 40
tmdTranslationSourceHash: 411ce978a57e7a45fb64223d34c44059
---

Crossplane Compositionsを使用してDynamoDBテーブルをプロビジョニングしたので、アプリケーションが新しいテーブルで正しく動作することを確認するためにテストを行いましょう。

まず、更新された設定を使用していることを確認するために、ポッドを再起動する必要があります：

```bash
$ kubectl rollout restart -n carts deployment/carts
$ kubectl rollout status -n carts deployment/carts --timeout=2m
deployment "carts" successfully rolled out
```

アプリケーションにアクセスするために、前のセクションと同じロードバランサーを使用します。そのホスト名を取得しましょう：

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

このURLをWebブラウザにコピーしてアプリケーションにアクセスできるようになりました。Webストアのユーザーインターフェイスが表示され、ユーザーとしてサイトを閲覧できます。

<Browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

**Carts**モジュールが実際に新しくプロビジョニングされたDynamoDBテーブルを使用していることを確認するには、以下の手順に従ってください：

1. Webインターフェイスで、カートにいくつかのアイテムを追加します。
2. 以下のスクリーンショットのように、アイテムがカートに表示されることを確認します：

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

これらのアイテムがDynamoDBテーブルに保存されていることを確認するために、次のコマンドを実行します：

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-crossplane"
```

このコマンドは、カートに追加したアイテムを含むDynamoDBテーブルの内容を表示します。

おめでとうございます！Crossplane Compositionsを使用してAWSリソースを正常に作成し、アプリケーションがこれらのリソースで正しく動作していることを確認しました。これは、Kubernetesクラスターから直接クラウドリソースを管理するためのCrossplaneの力を示しています。
