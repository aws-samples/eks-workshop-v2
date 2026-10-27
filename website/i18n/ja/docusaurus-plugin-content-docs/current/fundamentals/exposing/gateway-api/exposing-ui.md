---
title: "UI の公開"
sidebar_position: 10
tmdTranslationSourceHash: 1efb3668b1217f800a23c87a73944820
---

このセクションでは、UI アプリケーションを Application Load Balancer 経由で公開するために必要な Gateway API リソースを作成します。

## GatewayClass の作成

GatewayClass は、どのコントローラーが Gateway リソースの管理を担当するかを定義します。AWS Load Balancer Controller を使用する GatewayClass を作成します:

::yaml{file="manifests/modules/exposing/gateway-api/exposing-ui/gatewayclass.yaml" paths="spec.controllerName"}

これにより、`aws-alb` クラスを参照する Gateway は AWS Load Balancer Controller によって処理されることを Kubernetes に指示します。

GatewayClass を適用します:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/exposing-ui/gatewayclass.yaml
```

## Load Balancer の設定

LBC v3.x で Gateway API を使用する場合、Load Balancer の設定はアノテーションではなく `LoadBalancerConfiguration` CRD を通じて行われます。このリソースは ALB のスキームを定義します:

::yaml{file="manifests/modules/exposing/gateway-api/exposing-ui/loadbalancerconfig.yaml" paths="spec.scheme"}

`scheme: internet-facing` により、ALB がインターネットから公開アクセス可能になります。

LoadBalancerConfiguration を適用します:

```bash
$ export SOURCE_RANGES=$(echo $INBOUND_CIDRS | jq -R 'split(",")')
$ cat ~/environment/eks-workshop/modules/exposing/gateway-api/exposing-ui/loadbalancerconfig.yaml | envsubst | kubectl apply -f -
```

## Gateway の作成

Gateway リソースは実際の Load Balancer インフラストラクチャをプロビジョニングします。これは GatewayClass と LoadBalancerConfiguration を参照します:

::yaml{file="manifests/modules/exposing/gateway-api/exposing-ui/gateway.yaml" paths="spec.gatewayClassName,spec.infrastructure,spec.listeners"}

重要なポイント:

1. `gatewayClassName: aws-alb` は、この Gateway を作成した GatewayClass にリンクします
2. `infrastructure.parametersRef` は ALB 設定用の LoadBalancerConfiguration を参照します
3. リスナーはポート 80 で HTTP トラフィックを受け入れます

Gateway を適用します:

```bash timeout=600
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/exposing-ui/gateway.yaml
$ kubectl wait --for=condition=Programmed gateway/retail-store-gateway -n ui --timeout=600s
```

## HTTPRoute の作成

HTTPRoute は、Gateway に到着したトラフィックをバックエンドサービスにどのようにルーティングするかを定義します。パスプレフィックス `/` を持つすべてのトラフィックを UI サービスにルーティングします:

::yaml{file="manifests/modules/exposing/gateway-api/exposing-ui/httproute-ui.yaml" paths="spec.parentRefs,spec.rules"}

1. `parentRefs` はこのルートを Gateway にリンクします
2. ルールは `/` で始まるすべてのパスに一致し、トラフィックをポート 80 の `ui` サービスに転送します

HTTPRoute を適用します:

```bash hook=exposing-ui hookTimeout=430
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/exposing-ui/httproute-ui.yaml
```

## リソースの検証

すべてのリソースが正常に作成されたことを確認します:

```bash
$ kubectl get gatewayclass
NAME      CONTROLLER              ACCEPTED   AGE
aws-alb   gateway.k8s.aws/alb     True       2m
$ kubectl get gateway -n ui
NAME                    CLASS     ADDRESS                                                         PROGRAMMED   AGE
retail-store-gateway    aws-alb   k8s-ui-retailst-xxxxxxxxxx.us-west-2.elb.amazonaws.com          True         2m
$ kubectl get httproute -n ui
NAME       HOSTNAMES   AGE
ui-route               2m
```

Gateway ALB 経由で UI にアクセスします:

```bash
$ export GATEWAY_URL=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')
$ echo "http://${GATEWAY_URL}"
http://k8s-ui-retailst-xxxxxxxxxx.us-west-2.elb.amazonaws.com
```

Gateway でプロビジョニングされた ALB を通じて、ブラウザで retail store の UI にアクセスできるようになりました。

<Browser url="http://k8s-ui-retailst-xxxxxxxxxx.us-west-2.elb.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

