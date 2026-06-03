---
title: "パスベースルーティング"
sidebar_position: 20
tmdTranslationSourceHash: '3ec3358cbfbf9332df120c0bae8b49e2'
---

Gateway API の主要な利点の1つは、単一の Gateway から複数の名前空間にまたがる複数のバックエンドサービスにトラフィックをルーティングできることです。このセクションでは、`/catalog` リクエストを Catalog API に転送する2つ目の HTTPRoute を追加し、既存の UI ルートは引き続き他のすべてのトラフィックを処理します。

## 現在の状態

現時点では、`ui` 名前空間に単一の HTTPRoute（`ui-route`）があり、パスプレフィックス `/` を持つすべてのトラフィックを UI サービスにルーティングしています：

```bash
$ kubectl get httproute -n ui
NAME       HOSTNAMES   AGE
ui-route               5m
```

Gateway ALB へのすべてのリクエストは、パスに関係なく現在 UI アプリケーションに到達します。

## Catalog HTTPRoute の追加

`catalog` 名前空間に新しい HTTPRoute を作成し、パスプレフィックス `/catalog` を持つリクエストを Catalog サービスにルーティングします：

::yaml{file="manifests/modules/exposing/gateway-api/path-based-routing/httproute-catalog.yaml" paths="metadata.namespace,spec.parentRefs,spec.rules"}

重要なポイント：

1. HTTPRoute は `catalog` 名前空間に作成され、ルーティング先のサービスと同じ場所に配置されます
2. `parentRefs` フィールドは `ui` 名前空間の Gateway `retail-store-gateway` を参照します — これが名前空間をまたぐルーティングです
3. ルールはパスプレフィックス `/catalog` を持つリクエストをマッチし、それらを `catalog` サービスのポート 80 に転送します

Catalog HTTPRoute を適用します：

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/path-based-routing/httproute-catalog.yaml
```

## Catalog ヘルスチェックの設定

catalog サービスは、デフォルトのルートパス `/` ではなく `/health` でヘルスエンドポイントを公開します。ALB にヘルスチェック場所を伝えるために `TargetGroupConfiguration` が必要です：

::yaml{file="manifests/modules/exposing/gateway-api/path-based-routing/targetgroupconfig-catalog.yaml" paths="spec.targetReference,spec.defaultConfiguration.healthCheckConfig"}

1. `targetReference` は catalog Service を識別します
2. `healthCheckPath: /health` は ALB に `/` の代わりに `/health` をチェックするよう指示します

TargetGroupConfiguration を適用します：

```bash hook=path-routing hookTimeout=180
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/path-based-routing/targetgroupconfig-catalog.yaml
```

## 両方のルートを検証

両方の HTTPRoute が Gateway にアタッチされていることを確認します：

```bash
$ kubectl get httproute -A
NAMESPACE   NAME            HOSTNAMES   AGE
ui          ui-route                    5m
catalog     catalog-route               30s
```

`/catalog` パスが Catalog API の JSON を返すことをテストします：

```bash timeout=60
$ export GATEWAY_URL=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')
$ curl -s $GATEWAY_URL/catalog/products | jq .
```

Catalog サービスから製品データを含む JSON レスポンスが返されます。

ルートパス `/` がまだ UI を返すことを確認します：

```bash
$ curl --head -X GET -s $GATEWAY_URL
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 19973
Connection: keep-alive
Content-Language: en-US
```

`Content-Type: text/html` レスポンスは UI サービスが `/` で応答していることを確認し、Catalog API は `/catalog` でアクセス可能になりました — 両方とも同じ Gateway ALB を通じて提供されています。

## 名前空間をまたぐルーティング

このパターンは、Gateway API の従来の Ingress に対する主要な利点の1つを示しています。Ingress では、ルーティングルールとロードバランサー設定が単一のリソースに密結合されており、名前空間をまたいで ALB を共有するには IngressGroup アノテーションのような回避策が必要です。

Gateway API では、アーキテクチャが役割指向です：

- **クラスター運用者**は1つの名前空間で Gateway（ロードバランサーインフラストラクチャ）を管理します
- **アプリケーションチーム**は自分の名前空間で HTTPRoute を作成し、`parentRefs` を介して共有 Gateway を参照します

Catalog チームは、Gateway が存在する `ui` 名前空間へのアクセスを必要とせずに、`catalog` 名前空間で独立してルーティングルールを管理できます。Gateway コントローラーは、Gateway がリスナー設定を通じて許可していれば、アタッチメントを自動的に処理します。

この関心事の分離により、Gateway API は、異なるチームが異なるサービスを所有しながら共通のインフラストラクチャを共有するマルチチームクラスターに自然に適合します。

