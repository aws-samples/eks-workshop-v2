---
title: "ラボセットアップ：Chaos Mesh、スケーリング、Podアフィニティ"
sidebar_position: 90
description: "ポッドのスケーリング方法、Podアンチアフィニティ設定の追加、およびアベイラビリティーゾーン間でのポッド分布を視覚化するヘルパースクリプトの使用方法を学びます。"
tmdTranslationSourceHash: 6c950c3616333240e58e52096390f35a
---

このガイドでは、高可用性のプラクティスを実装してUIサービスの回復力を強化するための手順を説明します。helmのインストール、UIサービスのスケーリング、Podアンチアフィニティの実装、およびアベイラビリティーゾーン間のポッド分布を視覚化するヘルパースクリプトの使用方法について説明します。

## Chaos Meshのインストール

クラスターの回復力テスト能力を強化するために、Chaos Meshをインストールします。Chaos MeshはKubernetes環境向けの強力なカオスエンジニアリングツールです。さまざまな障害シナリオをシミュレートし、アプリケーションがどのように応答するかをテストすることができます。

Helmを使用して、クラスターにChaos Meshをインストールしましょう：

```bash timeout=240
$ helm repo add chaos-mesh https://charts.chaos-mesh.org
$ helm upgrade --install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace chaos-mesh \
  --create-namespace \
  --version 2.5.1 \
  --set dashboard.create=true \
  --wait

Release "chaos-mesh" does not exist. Installing it now.
NAME: chaos-mesh
LAST DEPLOYED: Tue Aug 20 04:44:31 2024
NAMESPACE: chaos-mesh
STATUS: deployed
REVISION: 1
TEST SUITE: None

```

## スケーリングとトポロジースプレッド制約

Kustomizeパッチを使用してUIデプロイメントを変更し、5つのレプリカにスケールアップし、トポロジースプレッド制約ルールを追加します。これにより、UIポッドが異なるノードに分散され、ノード障害の影響が軽減されます。

パッチファイルの内容は次のとおりです：

```kustomization
modules/observability/resiliency/high-availability/config/scale_and_affinity_patch.yaml
Deployment/ui
```

Kustomizeパッチと[Kustomizationファイル](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/high-availability/config/kustomization.yaml)を使用して変更を適用します：

```bash timeout=120
$ kubectl delete deployment ui -n ui
$ kubectl apply -k ~/environment/eks-workshop/modules/observability/resiliency/high-availability/config/
```

## 小売店のアクセシビリティの確認

これらの変更を適用した後、小売店がアクセス可能であることを確認することが重要です：

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

このコマンドが完了すると、URLが出力されます。新しいブラウザタブでこのURLを開いて、小売店がアクセス可能で正常に機能していることを確認します。

:::tip
小売URLが操作可能になるまで5〜10分かかる場合があります。
:::

## ヘルパースクリプト：AZごとのポッドの取得

`get-pods-by-az.sh`スクリプトは、ターミナルで異なるアベイラビリティゾーンにわたるKubernetesポッドの分布を視覚化するのに役立ちます。スクリプトファイルはGitHubで[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/resiliency/scripts/get-pods-by-az.sh)で確認できます。

### スクリプトの実行

スクリプトを実行してアベイラビリティゾーン間のポッド分布を確認するには、次を実行します：

```bash
$ timeout 10s ~/$SCRIPT_DIR/get-pods-by-az.sh | head -n 30

------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-6fzrk   1/1   Running   0     56s
       ui-6dfb84cf67-dsp55   1/1   Running   0     56s

------us-west-2b------
  ip-10-42-153-179.us-west-2.compute.internal:
       ui-6dfb84cf67-2pxnp   1/1   Running   0     59s

------us-west-2c------
  ip-10-42-186-246.us-west-2.compute.internal:
       ui-6dfb84cf67-n8x4f   1/1   Running   0     61s
       ui-6dfb84cf67-wljth   1/1   Running   0     61s

```

:::info
これらの変更の詳細については、次のセクションをご覧ください：

- [Chaos Mesh](https://chaos-mesh.org/)
- [Podアフィニティとアンチアフィニティ](../../fundamentals/compute/managed-node-groups/basics/affinity/)

:::
