---
title: "複数のIngressパターン"
sidebar_position: 30
kiteTranslationSourceHash: 2e75c3dcc5a0600975e14bd41effa2a4
---

同じEKSクラスター内で複数のIngressオブジェクトを活用することは一般的です。例えば、複数の異なるワークロードを公開するためなどです。デフォルトでは、各IngressはそれぞれALBの作成につながりますが、IngressGroup機能を活用することで複数のIngressリソースをグループ化できます。コントローラーはIngressGroup内のすべてのIngressのルールを自動的に統合し、1つのALBでそれらをサポートします。さらに、Ingressで定義されたほとんどのアノテーションは、そのIngressによって定義されたパスにのみ適用されます。

この例では、`ui`コンポーネントと同じALBを通して`catalog` APIを公開し、パスベースのルーティングを活用して適切なKubernetesサービスにリクエストをディスパッチします。

まず、`ui`コンポーネントの新しいIngressを作成します：

::yaml{file="manifests/modules/exposing/ingress/multiple-ingress/ingress-ui.yaml" paths="metadata.annotations,spec.rules.0"}

1. アノテーション`alb.ingress.kubernetes.io/group.name`を追加してIngressGroupを`retail-app-group`に設定します
2. rulesセクションは、ALBがトラフィックをどのようにルーティングすべきかを表現するために使用されます。`ui`コンポーネントでは、パス`/`で始まるすべてのHTTPリクエストをポート80のKubernetesサービス`ui`にルーティングします


次に、`catalog`コンポーネント用に別のIngressを作成します：

::yaml{file="manifests/modules/exposing/ingress/multiple-ingress/ingress-catalog.yaml" paths="metadata.annotations,spec.rules.0"}

1. `ui`コンポーネントと同じIngressGroupを指定するには、アノテーションセクションで`alb.ingress.kubernetes.io/group.name`を`retail-app-group`に設定します
2. rulesセクションは、ALBがトラフィックをどのようにルーティングすべきかを表現するために使用されます。`catalog`コンポーネントでは、パス`/catalog`で始まるすべてのHTTPリクエストをポート80のKubernetesサービス`catalog`にルーティングします

これらのマニフェストをクラスターに適用します：

```bash wait=60
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/multiple-ingress
```

これで、`-multi`で終わる2つの追加のIngressオブジェクトがクラスターに作成されます：

```bash
$ kubectl get ingress -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE      NAME      CLASS   HOSTS   ADDRESS                                                              PORTS   AGE
catalog-multi  catalog   alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
ui-multi       ui        alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
ui             ui        alb     *       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com                     80      4m3s
```

両方の`ADDRESS`が同じURLであることに注目してください。これは、これら2つのIngressオブジェクトが同じALBの背後にグループ化されているためです。

ALBリスナーを見て、これがどのように機能するか確認しましょう：

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-retailappgroup`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN | jq -r '.Listeners[0].ListenerArn')
$ aws elbv2 describe-rules --listener-arn $LISTENER_ARN
```

このコマンドの出力は次のことを示します：

- パスプレフィックス`/catalog`を持つリクエストはcatalogサービスのターゲットグループに送信されます
- それ以外はuiサービスのターゲットグループに送信されます
- デフォルトのバックアップとして、漏れたリクエストのために404があります

AWS consoleで新しいALB設定も確認できます：

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=retail-app-group;sort=loadBalancerName" service="ec2" label="EC2コンソールを開く"/>

ロードバランサーのプロビジョニングが完了するまで待つには、次のコマンドを実行できます：

```bash timeout=180
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

以前と同様にブラウザで新しいIngress URLにアクセスして、Webユーザーインターフェイスがまだ機能していることを確認してください：

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com
```

次に、catalogサービスに向けたパスにアクセスしてみましょう：

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl $ADDRESS/catalog/products | jq .
```

catalogサービスからJSONペイロードが返されるでしょう。これは、同じALBを通じて複数のKubernetesサービスを公開できたことを示しています。
