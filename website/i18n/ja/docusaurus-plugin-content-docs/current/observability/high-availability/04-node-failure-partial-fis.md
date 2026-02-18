---
title: "FISを使用した部分的なノード障害のシミュレーション"
sidebar_position: 150
description: "AWS Fault Injection Simulatorを使用してKubernetes環境における部分的なノード障害をシミュレーションし、アプリケーションの回復力をテストします。"
tmdTranslationSourceHash: 29b302119a2fce9ed4e46d69454d37ed
---

## AWS Fault Injection Simulator (FIS) の概要

AWS Fault Injection Simulator (FIS) は、AWSワークロードに対して制御された障害注入実験を実行できるフルマネージドサービスです。FISを使用することで、さまざまな障害シナリオをシミュレーションできます。これは以下の点で重要です：

1. 高可用性構成の検証
2. 自動スケーリングおよび自己修復機能のテスト
3. 潜在的な単一障害点の特定
4. インシデント対応手順の改善

FISを使用すると、以下のことが可能になります：

- 隠れたバグやパフォーマンスのボトルネックを発見する
- システムがストレス下でどのように動作するかを観察する
- 自動復旧手順を実装および検証する
- 一貫した動作を確保するために繰り返し実験を実施する

今回のFIS実験では、EKSクラスター内の部分的なノード障害をシミュレーションし、アプリケーションがどのように反応するかを観察します。これにより、耐障害性のあるシステムを構築するための実践的な知見が得られます。

:::info
AWS FISの詳細については、以下をご覧ください：

- [AWS Fault Injection Serviceとは？](https://docs.aws.amazon.com/fis/latest/userguide/what-is.html)
- [AWS Fault Injection Simulator コンソール](https://console.aws.amazon.com/fis/home)
- [AWS Systems Manager, Automation](https://console.aws.amazon.com/systems-manager/automation/executions)

:::

## 実験の詳細

この実験は、前回の手動によるノード障害シミュレーションとは以下の点で異なります：

1. **自動実行**: FISが実験を管理し、前回の実験での手動スクリプト実行と比較してより制御された繰り返し可能なテストが可能になります。
2. **部分的な障害**: 単一ノードの完全な障害をシミュレーションするのではなく、FISを使用して複数のノードにわたる部分的な障害をシミュレーションできます。これにより、より微妙で現実的な障害シナリオが提供されます。
3. **スケール**: FISでは複数のノードを同時に対象にすることができます。これにより、手動実験での単一ノード障害と比較して、より大規模なアプリケーションの回復力をテストできます。
4. **精度**: インスタンスを終了する正確な割合を指定でき、実験に対する細かい制御が可能になります。この程度の制御は、限られたノード全体を終了することしかできなかった手動実験では不可能でした。
5. **最小限の中断**: FIS実験は、テスト中のサービス可用性を維持するように設計されています。一方、手動ノード障害はリテールストアのアクセス性に一時的な中断を引き起こす可能性があります。

これらの違いにより、アプリケーションの障害に対する回復力をより包括的かつ現実的にテストすることができ、実験パラメータをより適切に制御できます。この実験では、FISがノードグループの2つのインスタンスの66%を終了し、クラスターの重要な部分障害をシミュレーションします。前回の実験と同様に、この実験も繰り返し実行可能です。

## ノード障害実験の作成

部分的なノード障害をシミュレーションするための新しいAWS FIS実験テンプレートを作成します：

```bash wait=30
$ export NODE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"NodeDeletion","targets":{"Nodegroups-Target-1":{"resourceType":"aws:eks:nodegroup","resourceTags":{"eksctl.cluster.k8s.io/v1alpha1/cluster-name":"eks-workshop"},"selectionMode":"COUNT(2)"}},"actions":{"nodedeletion":{"actionId":"aws:eks:terminate-nodegroup-instances","parameters":{"instanceTerminationPercentage":"66"},"targets":{"Nodegroups":"Nodegroups-Target-1"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix": "'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## 実験の実行

FIS実験を実行してノード障害をシミュレーションし、応答を監視します：

```bash timeout=300
$ aws fis start-experiment --experiment-template-id $NODE_EXP_ID --output json && timeout --preserve-status 240s ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-127-82.us-west-2.compute.internal:
       ui-6dfb84cf67-s6kw4   1/1   Running   0     2m16s
       ui-6dfb84cf67-vwk4x   1/1   Running   0     4m54s

------us-west-2b------

------us-west-2c------
  ip-10-42-180-16.us-west-2.compute.internal:
       ui-6dfb84cf67-29xtf   1/1   Running   0     79s
       ui-6dfb84cf67-68hbw   1/1   Running   0     79s
       ui-6dfb84cf67-plv9f   1/1   Running   0     79s

```

このコマンドはノード障害をトリガーし、4分間ポッドを監視します。これにより、クラスターが容量の大部分を失った場合にどのように応答するかを観察できます。

実験中、以下のことが観察されるはずです：

1. 約1分後、1つ以上のノードがリストから消え、シミュレーションされた部分的なノード障害を表します。
2. 次の2分間で、ポッドが残りの正常なノードに再スケジュールされ、再配布されていることに気づくでしょう。
3. その直後に、終了したノードを置き換えるための新しいノードがオンラインになるのが見えるでしょう。

FISを使用しないノード障害とは異なり、リテールのURLは運用状態を維持し続けるはずです。

:::note
ノードを確認してポッドを再バランスするには、以下を実行できます：

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

## リテールストアの可用性の確認

部分的なノード障害の間もリテールストアアプリケーションが運用状態を維持していることを確認します。以下のコマンドを使用して可用性を確認します：

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

:::tip
リテールURLが運用可能になるまで10分ほどかかる場合があります。
:::

部分的なノード障害にもかかわらず、リテールストアはトラフィックを提供し続けるはずであり、デプロイメント設定の回復力を示しています。

## 結論

AWS FISを使用したこの部分的なノード障害シミュレーションは、Kubernetesクラスターの回復力に関するいくつかの重要な側面を示しています：

1. Kubernetesによるノード障害の自動検出
2. 障害が発生したノードから正常なノードへのポッドの迅速な再スケジュール
3. 重大なインフラストラクチャ障害中にサービスの可用性を維持するクラスターの能力
4. 障害が発生したノードを置き換えるための自動スケーリング機能

この実験から得られる重要なポイント：

- 複数のノードとアベイラビリティーゾーンにワークロードを分散することの重要性
- ポッドに適切なリソース要求と制限を設定することの価値
- Kubernetesの自己修復メカニズムの効果
- ノード障害を検出し対応するための堅牢な監視とアラートシステムの必要性

このような実験にAWS FISを活用することで、いくつかの利点が得られます：

1. **繰り返し可能性**: 一貫した動作を確保するために、この実験を複数回実行できます。
2. **自動化**: FISを使用すると定期的な回復力テストをスケジュールでき、システムが時間の経過とともに耐障害性能力を維持することを確保できます。
3. **包括的なテスト**: 複数のAWSサービスを含むより複雑なシナリオを作成して、アプリケーションスタック全体をテストできます。
4. **制御されたカオス**: FISは、本番システムに意図しない損害を与えるリスクなく、カオスエンジニアリング実験を実施するための安全で管理された環境を提供します。

このような実験を定期的に実行することで、システムの回復力に対する信頼を構築し、アーキテクチャと運用手順を継続的に改善するための貴重な洞察を得ることができます。
