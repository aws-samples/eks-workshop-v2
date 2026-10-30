---
title: Namespace
sidebar_position: 10
tmdTranslationSourceHash: 509512e7f57ecd083a4d8cd800de1620
---

# Namespace

**Namespace** は、単一の Kubernetes クラスター内でリソースを整理し分離する方法を提供します。物理的なクラスター内の仮想クラスターのように考えることができます。これにより、同じ基盤インフラストラクチャを共有しながら、異なるアプリケーション、環境、またはチームを分離できます。

Namespace は、コンピューター上のフォルダーのようなものと考えることができます。関連するファイル（リソース）を混在させることなくグループ化できます。

Namespace は以下を提供します:
- **整理:** 関連するリソースをグループ化（アプリケーションのすべてのコンポーネントなど）
- **分離:** 異なるアプリケーションやチーム間でのリソースの競合を防止
- **リソース管理:** 特定のリソースグループにクォータと制限を適用
- **アクセス制御:** Kubernetes のパーミッション（RBAC — Role-Based Access Control と呼ばれる）を使用して、誰がリソースにアクセスしたり変更したりできるかを決定

このセクションでは、小売店アプリケーションのさまざまなコンポーネントを使用して、Namespace がリソースをどのように整理するかを探ります。

### デフォルトの Namespace
すべての Kubernetes クラスターは、いくつかの組み込み Namespace から始まります。これらは、クラスターがプロビジョニングされたときに自動的に作成されます:

- **default** - Namespace を指定しない場合にリソースが配置される場所
- **kube-system** - DNS やネットワーキングなどのシステムコンポーネント
- **kube-public** - 公開読み取り可能なリソース
- **kube-node-lease** - Node のハートビート情報

```bash
$ kubectl get namespaces
NAME              STATUS   AGE
default           Active   1h
kube-node-lease   Active   1h
kube-public       Active   1h
kube-system       Active   1h
```

### 最初の Namespace の作成
小売店の UI コンポーネント用の Namespace を作成しましょう:

::yaml{file="manifests/base-application/ui/namespace.yaml" paths="kind,metadata.name,metadata.labels" title="namespace.yaml"}

1. `kind: Namespace`: 作成するリソースのタイプを Kubernetes に伝えます。
2. `metadata.name`: クラスター内でこの Namespace の一意の識別子。
3. `metadata.labels`: リソースを整理し分類するキーと値のペア。

`kubectl` を使用して設定ファイルを適用します
```bash
$ kubectl apply -f ~/environment/eks-workshop/base-application/ui/namespace.yaml
```

`kubectl create` コマンドを使用して直接 Namespace を作成することもできます。`catalog` サービス用の Namespace を作成し、ラベルを追加しましょう（ラベルはオプションですが、整理に役立ちます）:

```bash
$ kubectl create namespace catalog
$ kubectl label namespace catalog app.kubernetes.io/created-by=eks-workshop
```

両方の Namespace を確認しましょう:
```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
```

`-l` フラグは「ラベルセレクター」を表し、ラベルに基づいてリソースをフィルタリングします。この場合、`app.kubernetes.io/created-by=eks-workshop` というラベルを持つ Namespace のみを表示しています。これは、クラスター内のすべての Namespace の中から、このワークショップで作成されたリソースを見つけるのに役立ちます。

Namespace を詳しく見る
```bash
$ kubectl describe namespace ui
Name:         ui
Labels:       app.kubernetes.io/created-by=eks-workshop
              kubernetes.io/metadata.name=ui
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

### Namespace の使用
リソースを操作する際、Namespace は 2 つの方法で指定できます:

**`-n` フラグを使用:**
```bash
$ kubectl get all -n ui
```

**`--namespace` フラグを使用:**
```bash
$ kubectl get all --namespace ui
```


ヒント: `-A` フラグを使用して、すべての Namespace のリソースを表示することもできます:

```bash
$ kubectl get pods -A
```

### このワークショップでの Namespace
このワークショップでは、Namespace はサンプル小売店アプリケーションを構成するさまざまなマイクロサービスを分離するのに役立ちます。

- `ui` - フロントエンドユーザーインターフェース
- `catalog` - 商品カタログサービス
- `carts` - ショッピングカートサービス
- `checkout` - 注文処理サービス
- `orders` - 注文管理サービス

ラボ全体を通じて、次のようなコマンドが表示されます:
```bash
$ kubectl get pods -n ui
$ kubectl get secrets -n catalog
```

この整理により、以下が容易になります:
* どのコンポーネントがどのサービスに属しているかを確認
* 特定のサービスに設定を適用
* 特定のサービス内の問題をトラブルシューティング

## 覚えておくべき重要なポイント
* Namespace はリソースを整理し分離します
* 名前は Namespace 内で一意である必要があります
* ほとんどのリソースは Namespace に属し、一部はクラスター全体に存在します
* 一部のリソース（Node や PersistentVolume など）は Namespace に属さず、クラスターレベルで存在します
* 指定しない場合は default Namespace が使用されます
* リソースクォータとアクセス制御を有効にします

