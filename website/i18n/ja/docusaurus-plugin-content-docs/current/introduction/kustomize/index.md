---
title: Kustomize
sidebar_custom_props: { "module": true }
sidebar_position: 70
tmdTranslationSourceHash: 785ddb1ac12e1137a75c4433b9b12aa5
---

::required-time

:::tip 始める前に
このセクションのために環境を準備してください：

```bash timeout=300 wait=10
$ prepare-environment
```

:::

[Kustomize](https://kustomize.io/)は、宣言的な「kustomization」ファイルを使用してKubernetesマニフェストファイルを管理することができます。これにより、Kubernetesリソースの「ベース」マニフェストを表現し、構成、カスタマイズ、そして多くのリソースにわたる横断的な変更を簡単に適用することが可能になります。

## 小売ストアアプリケーションのデプロイ

まず、Kustomizeを使用して完全な小売ストアアプリケーションをデプロイしましょう。アプリケーションは連携して動作する複数のマイクロサービスで構成されています：

### ベースアプリケーションのデプロイ

最初に、ベース設定を使用して小売ストアアプリケーション全体をデプロイしましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

この単一のコマンドで、すべてのマイクロサービスがデプロイされます。何が作成されたか見てみましょう：

```bash
$ kubectl get pods -A -l app.kubernetes.io/created-by=eks-workshop
NAME                               READY   STATUS    RESTARTS   AGE
cart-6d4f8c9b8d-xyz12             1/1     Running   0          2m
catalog-7b5c9d8e9f-abc34          1/1     Running   0          2m
checkout-8c6d0e1f2g-def56         1/1     Running   0          2m
orders-9d7e2f3g4h-ghi78          1/1     Running   0          2m
ui-0e8f3g4h5i-jkl90              1/1     Running   0          2m
```

### Kustomizationの構造を理解する

ベースアプリケーションは、すべてのコンポーネントディレクトリを参照する`kustomization.yaml`ファイルを使用しています：

```bash
$ cat ~/environment/eks-workshop/base-application/kustomization.yaml
```

各サービスには、Kubernetesマニフェストを含む独自のディレクトリがあります：

```bash
$ ls ~/environment/eks-workshop/base-application/
cart/  catalog/  checkout/  orders/  ui/  kustomization.yaml
```

### オーバーレイによるカスタマイズ

それでは、カスタマイズを作成してKustomizeの力を見てみましょう。例えば、`checkout`サービスの`replicas`フィールドを1から3に更新して水平にスケールしてみましょう。

以下の`checkout` Deploymentのマニフェストファイルを見てみましょう：

```file
manifests/base-application/checkout/deployment.yaml
```

このYAMLファイルを手動で更新する代わりに、Kustomizeを使用して`spec/replicas`フィールドを1から3に更新します。

そのためには、以下のkustomizationを適用します。

- 最初のタブでは、適用するkustomizationを表示しています
- 2番目のタブでは、kustomizationが適用された後の更新された`Deployment/checkout`ファイルのプレビューを表示しています
- 最後に、3番目のタブでは変更点のdiffだけを表示しています

```kustomization
modules/introduction/kustomize/deployment.yaml
Deployment/checkout
```

このkustomizationを適用する最終的なKubernetes YAMLを生成するには、`kubectl`CLIにバンドルされている`kustomize`を呼び出す`kubectl kustomize`コマンドを使用します：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/introduction/kustomize
```

これにより多くのYAMLファイルが生成され、Kubernetesに直接適用できる最終的なマニフェストが表示されます。`kustomize`の出力を`kubectl apply`に直接パイプしてこれを実証してみましょう：

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/introduction/kustomize | kubectl apply -f -
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout configured
deployment.apps/checkout-redis unchanged
```

「checkout」関連のさまざまなリソースが「unchanged」であり、`deployment.apps/checkout`が「configured」になっていることに気付くでしょう。これは意図的なものです — `checkout`デプロイメントにのみ変更を適用したいからです。これは、前のコマンドを実行すると実際に2つのファイルが適用されたためです：上で見たKustomizeの`deployment.yaml`と、`~/environment/eks-workshop/base-application/checkout`フォルダ内のすべてのファイルにマッチする以下の`kustomization.yaml`ファイルです。`patches`フィールドは、パッチを適用する特定のファイルを指定します：

```file
manifests/modules/introduction/kustomize/kustomization.yaml
```

レプリカ数が更新されたことを確認するには、次のコマンドを実行します：

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-585c9b45c7-c456l   1/1     Running   0          2m12s
checkout-585c9b45c7-b2rrz   1/1     Running   0          2m12s
checkout-585c9b45c7-xmx2t   1/1     Running   0          40m
```

`kubectl kustomize`と`kubectl apply`の組み合わせを使用する代わりに、`kubectl apply -k <kustomization_directory>`（`-f`フラグの代わりに`-k`フラグを使用）で同じことを実現できます。このアプローチはこのワークショップを通じて使用され、マニフェストファイルの変更を適用しやすくしながら、適用される変更を明確に表示します。

試してみましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/kustomize
```

アプリケーションのマニフェストを初期状態に戻すには、単に元のマニフェストセットを適用するだけです：

```bash timeout=300 wait=30
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

いくつかのラボ演習で見られる別のパターンは次のようなものです：

```bash
$ kubectl kustomize ~/environment/eks-workshop/base-application \
  | envsubst | kubectl apply -f-
```

これは`envsubst`を使用して、Kubernetesマニフェストファイル内の環境変数プレースホルダーを、あなたの特定の環境に基づく実際の値に置き換えます。例えば、いくつかのマニフェストでは、EKSクラスター名を`$EKS_CLUSTER_NAME`で、またはAWSリージョンを`$AWS_REGION`で参照する必要があります。

## 高度なKustomizeパターン

### 環境固有の設定

Kustomizeは、異なる環境に対する異なる設定の管理に優れています。例えば：

- **ベース**: すべての環境で共有される共通の設定
- **開発オーバーレイ**: 低いリソース制限、デバッグロギングを有効化
- **本番オーバーレイ**: 高いリソース制限、複数のレプリカ、モニタリングを有効化

### 横断的な変更

Kustomizeの強みの1つは、複数のリソースに対して変更を行えることです。例えば：

- すべてのリソースにラベルを追加: `commonLabels`
- すべてのリソースにアノテーションを追加: `commonAnnotations`
- すべてのデプロイメントにリソース制限を設定
- イメージプルポリシーを一貫して設定

### 個別サービスのデプロイ

特定のkustomizationを使用して個別のサービスをデプロイすることもできます：

```bash
# catalogサービスのみをデプロイ
$ kubectl apply -k ~/environment/eks-workshop/base-application/catalog

# UIサービスのみをデプロイ
$ kubectl apply -k ~/environment/eks-workshop/base-application/ui
```

### 生成されたマニフェストの表示

変更を適用する前に、Kustomizeが生成する内容をプレビューできます：

```bash
$ kubectl kustomize ~/environment/eks-workshop/base-application/catalog
```

これにより、クラスターに実際に適用することなく、どのKubernetesリソースが作成されるかを正確に確認できます。

Kustomizeの仕組みを理解したので、[Getting Started](/docs/introduction/getting-started)ハンズオンラボに進むか、直接[基礎モジュール](/docs/fundamentals)に進むことができます。

Kustomizeについて詳しく知るには、公式Kubernetesの[ドキュメント](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)を参照してください。
