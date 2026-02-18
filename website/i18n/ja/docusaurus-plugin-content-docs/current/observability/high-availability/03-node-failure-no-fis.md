---
title: "FISを使用せずにノード障害をシミュレートする"
sidebar_position: 130
description: "AWS FISを使用せずに、アプリケーションの回復力をテストするためにKubernetes環境でノード障害を手動でシミュレートします。"
tmdTranslationSourceHash: d9a8781c19acbe227ff341dee4df27dd
---

## 概要

この実験では、Kubernetesクラスタでノード障害を手動でシミュレートし、特にリテールストアアプリケーションの可用性に焦点を当てて、デプロイされたアプリケーションへの影響を理解します。ノードの故障を意図的に引き起こすことで、Kubernetesが障害にどのように対処し、クラスタ全体の健全性を維持するかを観察できます。

`node-failure.sh`スクリプトは、ノード障害をシミュレートするためにEC2インスタンスを手動で停止します。使用するスクリプトは次のとおりです：

```file
manifests/modules/observability/resiliency/scripts/node-failure.sh
```

この実験は繰り返し実行可能であり、一貫した動作を確認したり、さまざまなシナリオや構成をテストしたりするために複数回実行することができることに注意することが重要です。

## 実験の実行

ノード障害をシミュレートしてその影響をモニタリングするには、次のコマンドを実行します：

```bash timeout=240
$ ~/$SCRIPT_DIR/node-failure.sh && timeout --preserve-status 180s  ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-dsp55   1/1   Running   0     10m
       ui-6dfb84cf67-gzd9s   1/1   Running   0     8m19s

------us-west-2b------
  ip-10-42-133-195.us-west-2.compute.internal:
       No resources found in ui namespace.

------us-west-2c------
  ip-10-42-186-246.us-west-2.compute.internal:
       ui-6dfb84cf67-4bmjm   1/1   Running   0     44s
       ui-6dfb84cf67-n8x4f   1/1   Running   0     10m
       ui-6dfb84cf67-wljth   1/1   Running   0     10m
```

このコマンドは選択したEC2インスタンスを停止し、2分間ポッドの分布をモニタリングして、システムがワークロードをどのように再分配するかを観察します。

実験中、次の一連のイベントが観察されるはずです：

1. 約1分後、リストから1つのノードが消えます。これはシミュレートされたノード障害を表しています。
2. ノード障害の直後に、ポッドが残りの正常なノードに再分配されるのがわかります。Kubernetesはノード障害を検出し、影響を受けたポッドを自動的に再スケジュールします。
3. 最初の障害から約2分後、故障したノードがオンラインに戻ります。

このプロセス全体を通じて、実行中のポッドの総数は一定に保たれ、アプリケーションの可用性が確保されます。

## クラスターの回復の検証

ノードがオンラインに戻るのを待っている間、クラスターの自己回復機能を確認し、必要に応じてポッドを再度リサイクルします。クラスターは多くの場合自分で回復するため、現在の状態を確認し、AZ全体にポッドが最適に分布していることを確認することに焦点を当てます。

まず、すべてのノードが`Ready`状態にあることを確認しましょう：

```bash timeout=300
$ EXPECTED_NODES=3 && while true; do ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l); if [ "$ready_nodes" -eq "$EXPECTED_NODES" ]; then echo "All $EXPECTED_NODES expected nodes are ready."; echo "Listing the ready nodes:"; kubectl get nodes | grep " Ready"; break; else echo "Waiting for all $EXPECTED_NODES nodes to be ready... (Currently $ready_nodes are ready)"; sleep 10; fi; done
```

このコマンドは`Ready`状態のノードの総数をカウントし、3つのアクティブなノードがすべて準備完了になるまで継続的にチェックします。

すべてのノードが準備完了になったら、ポッドを再デプロイしてノード間でバランスが取れていることを確認します：

```bash timeout=900 wait=30
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n carts -l app.kubernetes.io/component=dynamodb
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n checkout -l app.kubernetes.io/component=redis
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n orders -l app.kubernetes.io/component=mysql
$ kubectl delete pod --grace-period=0 --force -n ui -l app.kubernetes.io/component=service
$ kubectl delete pod --grace-period=0 --force -n catalog -l app.kubernetes.io/component=service
$ sleep 90
$ kubectl rollout status -n ui deployment/ui --timeout 180s
$ timeout 10s ~/$SCRIPT_DIR/get-pods-by-az.sh | head -n 30
```

これらのコマンドは次のアクションを実行します：

1. 既存のuiポッドを削除します。
2. uiポッドが自動的にプロビジョニングされるのを待ちます。
3. `get-pods-by-az.sh`スクリプトを使用して、アベイラビリティゾーン間でのポッドの分布を確認します。

## リテールストアの可用性の確認

ノード障害をシミュレートした後、リテールストアアプリケーションがアクセス可能なままであることを確認できます。次のコマンドを使用してその可用性を確認します：

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

このコマンドはイングレスのロードバランサーホスト名を取得し、それが利用可能になるまで待機します。準備ができたら、このURLからリテールストアにアクセスして、シミュレートされたノード障害にもかかわらず、それがまだ正常に機能していることを確認できます。

:::caution
リテールURLが動作するようになるまでに10分かかる場合があります。オプションで、`ctrl` + `z`を押して操作をバックグラウンドに移動させ、ラボを続行することができます。再度アクセスするには以下を入力してください：

```bash test=false
$ fg %1
```

`wait-for-lb`がタイムアウトするまでにURLが動作しない場合があります。その場合、コマンドを再度実行すると動作するようになるはずです：

```bash test=false
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
```

:::

## 結論

このノード障害シミュレーションは、Kubernetesクラスタの堅牢性と自己回復能力を示しています。この実験から得られる重要な観察と教訓は次のとおりです：

1. Kubernetesがノード障害を迅速に検出して適切に対応する能力。
2. 故障したノードから正常なノードへのポッドの自動的な再スケジューリングによるサービスの継続性の確保。
3. EKSマネージドノードグループを使用したEKSクラスタの自己回復プロセスにより、短時間で障害が発生したノードがオンラインに戻る。
4. ノード障害中にアプリケーションの可用性を維持するための適切なリソース割り当てとポッド分布の重要性。

このような実験を定期的に実行することで、以下のことが可能になります：

- ノード障害に対するクラスタの回復力を検証する。
- アプリケーションのアーキテクチャまたはデプロイ戦略における潜在的な弱点を特定する。
- 予期しないインフラストラクチャの問題に対処するシステムの能力に自信を持つ。
- インシデント対応手順と自動化を改良する。
