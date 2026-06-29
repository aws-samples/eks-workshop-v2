---
title: ConfigMaps
sidebar_position: 10
tmdTranslationSourceHash: '235f6b1872d5a004ae5c9639a5e6438f'
---

# ConfigMaps

**ConfigMaps** を使用すると、設定アーティファクトをイメージコンテンツから分離して、コンテナ化されたアプリケーションをポータブルに保つことができます。ConfigMaps は機密情報ではないデータをキーと値のペアで保存し、Pod は環境変数、コマンドライン引数、または設定ファイルとして使用できます。

ConfigMaps の利点：
- **設定管理:** アプリケーション設定をコードとは別に保存
- **環境の柔軟性:** 異なる環境で異なる設定を使用
- **実行時の更新:** コンテナイメージを再ビルドせずに設定を更新
- **ポータビリティ:** 異なる環境間でアプリケーションをポータブルに保つ

このラボでは、リテールストアの UI コンポーネント用に ConfigMap を作成し、バックエンドサービスへの接続方法を学びます。

### ConfigMap の作成

リテールストアの UI コンポーネント用の ConfigMap を作成しましょう。UI はバックエンドサービスの場所を知る必要があります：

::yaml{file="manifests/base-application/ui/configMap.yaml" paths="kind,metadata.name,data" title="ui-configmap.yaml"}

1. `kind: ConfigMap`: 作成するリソースのタイプを Kubernetes に指示します
2. `metadata.name`: namespace 内でこの ConfigMap を一意に識別します
4. `data`: 設定データを含むキーと値のペア

ConfigMap の設定を適用します：
```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/basics/configmaps/
```

### ConfigMap の確認

次に、作成した ConfigMap を確認してみましょう：

```bash
$ kubectl get configmaps -n ui
NAME               DATA   AGE
kube-root-ca.crt   1      2m51s
ui                 4      2m50s
```

ConfigMap の詳細情報を取得します：
```bash
$ kubectl describe configmap ui -n ui
Name:         ui
Namespace:    ui
Labels:       <none>
Annotations:  <none>

Data
====
RETAIL_UI_ENDPOINTS_CARTS:
----
http://carts.carts.svc:80

RETAIL_UI_ENDPOINTS_CATALOG:
----
http://catalog.catalog.svc:80

RETAIL_UI_ENDPOINTS_CHECKOUT:
----
http://checkout.checkout.svc:80

RETAIL_UI_ENDPOINTS_ORDERS:
----
http://orders.orders.svc:80


BinaryData
====

Events:  <none>
```

これにより以下が表示されます：
- **Data セクション** - ConfigMap に保存されているキーと値のペア
- **Labels** - 整理のためのメタデータタグ
- **Annotations** - 追加のメタデータ

### Pod での ConfigMaps の使用

次に、ConfigMap を使用する Pod を作成しましょう。UI Pod を更新して設定を使用します：

::yaml{file="manifests/modules/introduction/basics/configmaps/ui-pod-with-config.yaml" paths="spec.containers.0.envFrom" title="ui-pod-with-config.yaml"}

1. `envFrom.configMapRef`: ConfigMap のすべてのキーと値のペアを環境変数としてロードします

更新された Pod 設定を適用します：
```bash hook=ready
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/configmaps/ui-pod-with-config.yaml
```

### 設定のテスト

Pod が設定にアクセスできることを確認しましょう：

```bash
$ kubectl exec -n ui ui-pod -- env | grep RETAIL_UI_ENDPOINTS_CATALOG
RETAIL_UI_ENDPOINTS_CATALOG=http://catalog.catalog.svc:80
```

すべての ConfigMap 環境変数を確認することもできます：
```bash
$ kubectl exec -n ui ui-pod -- env | grep RETAIL_UI
RETAIL_UI_ENDPOINTS_CATALOG=http://catalog.catalog.svc:80
RETAIL_UI_ENDPOINTS_CARTS=http://carts.carts.svc:80
RETAIL_UI_ENDPOINTS_ORDERS=http://orders.orders.svc:80
RETAIL_UI_ENDPOINTS_CHECKOUT=http://checkout.checkout.svc:80
```

## 覚えておくべき重要なポイント

* ConfigMaps は機密情報ではない設定データを保存します
* コンテナイメージから設定を分離します
* 環境変数として使用したり、ファイルとしてマウントしたりできます
* 異なる環境で同じイメージを動作させることができます
* ConfigMap ごとに 1MB のサイズ制限があります

