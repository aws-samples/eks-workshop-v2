---
title: "カナリアデプロイメント"
sidebar_position: 30
tmdTranslationSourceHash: '9d9e00ea1be46189ef41abc4586cd177'
---

Gateway API は、重み付けトラフィック分割をネイティブにサポートしており、追加のツールや Service Mesh インフラストラクチャなしでカナリアデプロイメントを可能にします。このセクションでは、UI アプリケーションの新しいバージョンをデプロイし、HTTPRoute の重み付けを使用して、元のバージョンから新しいバージョンへトラフィックを段階的に移行します。

従来の Kubernetes Ingress では、重み付けトラフィック分割はネイティブにサポートされていません。これを実現するには、Istio や App Mesh のような Service Mesh が必要になります。Gateway API は、`backendRefs` の weight フィールドを通じて、これを第一級の機能として提供します。

## 新しい UI バージョンのデプロイ

まず、UI アプリケーションの第 2 バージョン（`ui-v2`）をデプロイします。これはオレンジ色のテーマを使用しており、元の青色のテーマと視覚的に区別できます。

::yaml{file="manifests/modules/exposing/gateway-api/canary/deployment-ui-v2.yaml" paths="metadata.name,spec.template.spec.containers.0.env"}

主な違いは `RETAIL_UI_THEME=orange` 環境変数で、これにより視覚的に異なるオレンジ色のテーマの UI が生成されます。

また、新しい Pod にトラフィックをルーティングするための Service も必要です。

::yaml{file="manifests/modules/exposing/gateway-api/canary/service-ui-v2.yaml" paths="metadata.name,spec.selector"}

両方のリソースを適用します。

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/deployment-ui-v2.yaml
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/service-ui-v2.yaml
```

新しい Pod が準備完了になるまで待ちます。

```bash timeout=120
$ kubectl wait --for=condition=Ready pods -l app.kubernetes.io/version=v2 -n ui --timeout=120s
```

## 90/10 カナリアルートの適用

次に、既存の `ui-route` HTTPRoute を、元の UI に 90%、ui-v2 に 10% のトラフィックを送信する重み付けバージョンに置き換えます。

::yaml{file="manifests/modules/exposing/gateway-api/canary/httproute-ui-canary.yaml" paths="spec.rules.0.backendRefs"}

`backendRefs` フィールドに、明示的な `weight` 値を持つ 2 つのエントリが含まれていることに注目してください。Gateway コントローラーは、これらの重み付けに基づいてトラフィックを比例的に分散します。

カナリア HTTPRoute を適用します。

```bash hook=canary hookTimeout=180
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/httproute-ui-canary.yaml
```

## トラフィック分割のテスト

Gateway に複数のリクエストを送信し、分散を観察します。約 10% のレスポンスがオレンジ色のテーマの ui-v2 から返されるはずです。

```bash timeout=60
$ export GATEWAY_URL=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')
$ for i in $(seq 1 20); do curl -s $GATEWAY_URL | grep "theme" ; done
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-orange.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-orange.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-orange.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-orange.css"theme: {
```

ほとんどのレスポンスが `theme-default` を返し、20 回のリクエストのうち約 1〜2 回が `theme-orange` を返すことが確認でき、90/10 のトラフィック分割が機能していることがわかります。

## 50/50 へのトラフィック増加

新しいバージョンが正しく動作していることを確認したら、カナリアの重み付けを 50% に増やします。

::yaml{file="manifests/modules/exposing/gateway-api/canary/httproute-canary-50-50.yaml" paths="spec.rules.0.backendRefs"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/httproute-canary-50-50.yaml
```

再度テストして、均等な分割を確認します。

```bash timeout=60
$ for i in $(seq 1 20); do curl -s $GATEWAY_URL | grep "theme" ; done
```

レスポンスの約半分がオレンジ色のテーマを返すことが確認できるはずです。

## ロールアウトの完了

新しいバージョンに満足したら、重み付けを 0/100 に設定して、すべてのトラフィックを ui-v2 に移行します。

::yaml{file="manifests/modules/exposing/gateway-api/canary/httproute-canary-0-100.yaml" paths="spec.rules.0.backendRefs"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/httproute-canary-0-100.yaml
```

すべてのトラフィックが新しいバージョンに移行したことを確認します。

```bash timeout=60
$ for i in $(seq 1 20); do curl -s $GATEWAY_URL | grep "theme" ; done
```

すべてのレスポンスがオレンジ色のテーマを返し、ui-v2 への完全な切り替えが確認できるはずです。

<Browser url="http://k8s-ui-retailst-xxxxxxxxxx.us-west-2.elb.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home-orange.webp').default}/>
</Browser>

## まとめ

このセクションでは、Gateway API のネイティブな重み付けトラフィック分割を使用して、段階的なカナリアデプロイメントを実行しました。

1. 視覚的に区別できる新しいバージョンの UI をデプロイ
2. リスクを最小限に抑えるために 90/10 の分割で開始
3. 新しいバージョンを検証した後、50/50 に増加
4. 0/100 の分割でロールアウトを完了

### Gateway API と Ingress の比較

| 機能 | Gateway API | Kubernetes Ingress |
|---|---|---|
| 重み付けトラフィック分割 | `backendRefs` の重み付けによりネイティブサポート | ネイティブにサポートされていない |
| カナリアデプロイメント | 組み込み済み、追加ツール不要 | Service Mesh またはアノテーションが必要 |
| クロスネームスペースルーティング | `parentRefs` によりネイティブサポート | IngressGroup などの回避策が必要 |
| ロール指向モデル | GatewayClass → Gateway → HTTPRoute | 単一の Ingress リソース |
| ルートごとの複数バックエンド | 重み付けとフィルターによりネイティブサポート | パスごとに単一のバックエンドに制限 |
| 段階的ロールアウト | 宣言的な重み付け更新 | 外部コントローラーが必要 |

Gateway API のネイティブなトラフィック分割により、カナリアデプロイメントが簡潔かつ宣言的になり、従来の Ingress で必要とされる追加の Service Mesh インフラストラクチャやカスタムアノテーションが不要になります。

