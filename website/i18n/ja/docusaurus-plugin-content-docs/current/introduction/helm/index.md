---
title: Helm
sidebar_custom_props: { "module": true }
sidebar_position: 50
kiteTranslationSourceHash: 5f7ef990a504bc7200491f65c8407b7a
---

::required-time

:::tip 始める前に
このセクション用に環境を準備してください：

```bash timeout=600 wait=10
$ prepare-environment introduction/helm
```

:::

このワークショップでは主にKustomizeと対話しますが、EKSクラスターに特定のパッケージをインストールするためにHelmを使用する状況があります。このラボでは、Helmの簡単な紹介を行い、事前にパッケージ化されたアプリケーションをインストールする方法を示します。

:::info

このラボでは、独自のワークロード用のHelmチャートの作成については説明しません。このトピックの詳細については、[ガイド](https://helm.sh/docs/chart_template_guide/)を参照してください。

:::

[Helm](https://helm.sh)はKubernetes用のパッケージマネージャーであり、Kubernetesアプリケーションの定義、インストール、アップグレードを支援します。Helmはチャートと呼ばれるパッケージングフォーマットを使用し、アプリケーションの実行に必要なKubernetesリソース定義がすべて含まれています。Helmを使用することで、Kubernetesクラスター上でのアプリケーションのデプロイと管理が簡素化されます。

## Helm CLI

`helm` CLIツールは通常、Kubernetesクラスターと組み合わせて使用され、アプリケーションのデプロイとライフサイクルを管理します。これにより、異なる環境間でのアプリケーションデプロイの自動化と標準化が容易になります。

CLIはすでに私たちのIDEにインストールされています：

```bash
$ helm version
```

## Helmチャートのインストール

サンプルアプリケーションのUIコンポーネントをKustomizeマニフェストではなく、Helmチャートを使用してインストールしてみましょう。Helmパッケージマネージャーを使用してチャートをインストールすると、そのチャートに対して新しい**リリース**が作成されます。各リリースはHelmによって追跡され、他のリリースとは独立してアップグレード、ロールバック、またはアンインストールすることができます。

まず既存のUIアプリケーションを削除しましょう：

```bash
$ kubectl delete namespace ui
```

次にチャートをインストールできます：

```bash hook=install
$ helm install ui \
  oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.2.1 \
  --create-namespace --namespace ui \
  --wait
```

このコマンドを次のように分解できます：

- Helmにチャートのインストールを指示する`install`サブコマンドを使用
- リリースに`ui`という名前を付ける
- 特定のバージョンで[ECR Public](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui-chart)にホストされているチャートを使用
- チャートを`ui`名前空間にインストール
- リリース内のPodが準備完了状態になるのを待機

チャートがインストールされたら、EKSクラスター内のリリースを一覧表示できます：

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART                               APP VERSION
ui     ui         1         2024-06-11 03:58:39.862100855 +0000 UTC  deployed  retail-store-sample-ui-chart-X.X.X
```

また、指定した名前空間で実行されているアプリケーションを確認できます：

```bash
$ kubectl get pod -n ui
NAME                     READY   STATUS    RESTARTS   AGE
ui-55fbd7f494-zplwx      1/1     Running   0          119s
```

## チャートオプションの設定

上記の例では、チャートを[デフォルト設定](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/ui/chart/values.yaml)でインストールしました。多くの場合、コンポーネントの動作を変更するためにインストール時にチャートに設定**値**を提供する必要があります。

インストール時にチャートに値を提供する一般的な方法は2つあります：

1. YAMLファイルを作成し、`-f`または`--values`フラグを使用してHelmに渡す
2. `--set`フラグに続けて`key=value`ペアを使用して値を渡す

これらの方法を組み合わせてUIリリースを更新してみましょう。次の`values.yaml`ファイルを使用します：

```file
manifests/modules/introduction/helm/values.yaml
```

これにより、Podにいくつかのカスタムのkubernetes注釈が追加され、UIテーマが上書きされます。

:::tip[どの値を使用すればよいかわからない場合]

多くのHelmチャートはレプリカ数やPod注釈などの一般的な側面を設定するための比較的一貫した値を持っていますが、各Helmチャートには独自の一意の設定セットがあります。特定のチャートをインストールおよび設定する際は、そのドキュメントで利用可能な設定値を確認する必要があります。

:::

また、`--set`フラグを使用して追加のレプリカを追加します：

```bash hook=replicas
$ helm upgrade ui \
  oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.2.1 \
  --create-namespace --namespace ui \
  --set replicaCount=3 \
  --values ~/environment/eks-workshop/modules/introduction/helm/values.yaml \
  --wait
```

リリースを一覧表示します：

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART                                APP VERSION
ui     ui         2         2024-06-11 04:13:53.862100855 +0000 UTC  deployed  retail-store-sample-ui-chart-X.X.X   X.X.X
```

**revision**列が**2**に更新されていることがわかります。これは、Helmが更新された設定を個別のリビジョンとして適用したためです。これにより、必要に応じて以前の設定にロールバックすることができます。

特定のリリースのリビジョン履歴は次のように表示できます：

```bash
$ helm history ui -n ui
REVISION  UPDATED                   STATUS      CHART                               APP VERSION  DESCRIPTION
1         Tue Jun 11 03:58:39 2024  superseded  retail-store-sample-ui-chart-X.X.X  X.X.X        Install complete
2         Tue Jun 11 04:13:53 2024  deployed    retail-store-sample-ui-chart-X.X.X  X.X.X        Upgrade complete
```

変更が反映されたことを確認するために、`ui`名前空間のPodを一覧表示します：

```bash
$ kubectl get pods -n ui
NAME                     READY   STATUS    RESTARTS   AGE
ui-55fbd7f494-4hz9b      1/1     Running   0          30s
ui-55fbd7f494-gkr2j      1/1     Running   0          30s
ui-55fbd7f494-zplwx      1/1     Running   0          5m
```

現在3つのレプリカが実行されていることがわかります。また、Deploymentを調査することで注釈が適用されたことを確認できます：

```bash
$ kubectl get -o yaml deployment ui -n ui | yq '.spec.template.metadata.annotations'
my-annotation: my-value
[...]
```

## リリースの削除

同様にCLIを使用してリリースをアンインストールすることもできます：

```bash
$ helm uninstall ui --namespace ui --wait
```

これにより、そのリリース用にチャートによって作成されたすべてのリソースがEKSクラスターから削除されます。

Helmの仕組みを理解したので、[Fundamentalsモジュール](/docs/fundamentals)に進みましょう。
