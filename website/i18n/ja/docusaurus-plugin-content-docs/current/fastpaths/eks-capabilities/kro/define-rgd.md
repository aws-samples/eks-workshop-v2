---
title: "CartsStack RGD の定義"
sidebar_position: 20
tmdTranslationSourceHash: 'e06a0d76315daf7519d73d5804b9e83d'
---

前のページで紹介した `CartsStack` RGD、つまりブループリントを記述しましょう。その2つの主要なセクションは `schema`（ユーザーが提供する入力）と `resources`（kro がそれらから作成するグラフ）です:

::yaml{file="manifests/modules/fastpaths/eks-capabilities/kro/rgd/cartsstack-rgd.yaml" paths="spec.schema,spec.resources"}

1. **`spec.schema`** は、生の OpenAPI ではなく、kro の **SimpleSchema** 構文（`string | required=true` の形式）を使用して、ユーザー向け CR の形状を宣言します。`image` や `replicas` のようなオプションフィールドはデフォルト値を取得するため、最小限のインスタンスは `tableName` と `namespace` のみを設定します。
2. **`spec.resources`** は kro が作成するグラフです。各エントリには `id`（他のリソースからその出力を参照するために使用）と `template`（実際のマニフェスト）があります。ユーザーの入力を取り込む `${schema.spec.X}` 参照と、リソース間の `${table.status...arn}` / `${sa.metadata.name}` 参照に注目してください。これが kro がそれらを作成する順序を推論する方法です。

RGD を適用します:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fastpaths/eks-capabilities/kro/rgd
resourcegraphdefinition.kro.run/cartsstack created
```

kro は RGD を同期的に検証します: 参照するリソースの実際の Kubernetes スキーマに対してすべての `${...}` 式を型チェックし、循環依存を検出します。何か問題がある場合、適用は説明的なエラーですぐに失敗します。

RGD が `Active` に達するまで待ちます。この時点で、kro はクラスタ内に `CartsStack` CRD を動的に生成して登録しています:

```bash timeout=120
$ kubectl wait rgd cartsstack --for=jsonpath='{.status.state}'=Active --timeout=60s
resourcegraphdefinition.kro.run/cartsstack condition met
```

新しい `CartsStack` kind が現在、Kubernetes API のファーストクラスであることを確認します:

```bash
$ kubectl api-resources --api-group=kro.run | grep -E 'NAME|cartsstacks'
NAME                       SHORTNAMES   APIVERSION         NAMESPACED   KIND
cartsstacks                             kro.run/v1alpha1   true         CartsStack
```

:::info
`cartsstacks` は、それを定義する RGD がクラスタースコープであっても **namespaced** です。RGD はクラスター全体に存在します。インスタンスは常に特定の Namespace 内に存在します。
:::

スキーマが存在します。次にインスタンスを適用します。

