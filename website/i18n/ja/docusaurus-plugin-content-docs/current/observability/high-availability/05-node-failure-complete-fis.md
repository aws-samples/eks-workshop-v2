---
title: "FISを使用した完全なノード障害のシミュレーション"
sidebar_position: 170
description: "AWSフォルト・インジェクション・シミュレーター（FIS）を使用して、Kubernetes環境における完全なノード障害の影響を実証します。"
tmdTranslationSourceHash: 54b49f6f0bbfaaaf81aaea50ea19b29e
---

## 概要

この実験は、以前の部分的なノード障害テストを拡張して、EKSクラスタ内のすべてのノードの完全な障害をシミュレーションします。これは本質的にクラスタ障害です。これにより、AWSフォルト・インジェクション・シミュレーター（FIS）を使用して、極端なシナリオをテストし、破滅的な状況下でのシステムの回復力を検証する方法が示されます。

## 実験の詳細

この実験は、部分的なノード障害と同様に繰り返し可能です。部分的なノード障害のシミュレーションとは異なり、この実験では：

1. すべてのノードグループのインスタンスの100％を終了します。
2. クラスタが完全な障害状態からの回復能力をテストします。
3. 完全な停止から完全な復元までの回復プロセス全体を観察できます。

## ノード障害実験の作成

完全なノード障害をシミュレーションするための新しいAWS FIS実験テンプレートを作成します：

```bash wait=30
$ export FULL_NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"ALL"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"100"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## 実験の実行

FIS実験を実行し、クラスタの応答を監視します：

```bash timeout=420
$ aws fis start-experiment --experiment-template-id $FULL_NODE_EXP_ID --output json && timeout --preserve-status 360s ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-106-250.us-west-2.compute.internal:
       No resources found in ui namespace.

------us-west-2b------
  ip-10-42-141-133.us-west-2.compute.internal:
       ui-6dfb84cf67-n9xns   1/1   Running   0     4m8s
       ui-6dfb84cf67-slknv   1/1   Running   0     2m48s

------us-west-2c------
  ip-10-42-179-59.us-west-2.compute.internal:
       ui-6dfb84cf67-5xht5   1/1   Running   0     4m52s
       ui-6dfb84cf67-b6xbf   1/1   Running   0     4m10s
       ui-6dfb84cf67-fpg8j   1/1   Running   0     4m52s
```

このコマンドは、実験を観察しながら6分間にわたってポッドの分布を表示します。以下のことが観察できるでしょう：

1. 実験が開始されてすぐに、すべてのノードとポッドが消えます。
2. 約2分後、最初のノードといくつかのポッドがオンラインに戻ります。
3. 約4分後、2番目のノードが表示され、さらに多くのポッドが起動します。
4. 6分後、最後のノードがオンラインになるにつれて回復が続きます。

実験の深刻度のため、テスト中は小売店のURLは稼働状態を維持しません。最後のノードが稼働状態になった後、URLは復活するはずです。このテスト後にノードが稼働状態にならない場合は、`~/$SCRIPT_DIR/verify-clsuter.sh`を実行して、最後のノードの状態が実行中に変わるのを待ってから先に進みます。

:::note
ノードとポッドの再分配を確認するには、以下を実行できます：

```bash timeout=900 wait=30
$ EXPECTED_NODES=3 && while true; do ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l); if [ "$ready_nodes" -eq "$EXPECTED_NODES" ]; then echo "All $EXPECTED_NODES expected nodes are ready."; echo "Listing the ready nodes:"; kubectl get nodes | grep " Ready"; break; else echo "Waiting for all $EXPECTED_NODES nodes to be ready... (Currently $ready_nodes are ready)"; sleep 10; fi; done
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

:::

## 小売店の可用性の確認

小売アプリケーションの回復を確認します：

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

:::tip
小売URLが稼働状態になるまで10分ほどかかる場合があります。
:::

## 結論

この実験は以下を示しています：

1. 破滅的な障害に対するクラスタの応答。
2. すべての障害ノードを置き換えるオートスケーリングの有効性。
3. Kubernetesがすべてのポッドを新しいノードに再スケジュールする能力。
4. 完全な障害からのシステム全体の回復時間。

主な学び：

- 堅牢なオートスケーリング設定の重要性。
- 効果的なポッドの優先順位とプリエンプション設定の価値。
- 完全なクラスタ障害に耐えうるアーキテクチャの必要性。
- 極端なシナリオの定期的なテストの重要性。

FISをこのようなテストに使用することで、破滅的な障害を安全にシミュレーションし、回復手順を検証し、重要な依存関係を特定し、回復時間を測定することができます。これにより、災害復旧計画の改良とシステム全体の回復力の向上に役立ちます。
