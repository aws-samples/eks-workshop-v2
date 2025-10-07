---
title: "AZ障害のシミュレーション"
sidebar_position: 210
description: "この実験は、AWS EKSでホストされているKubernetes環境のレジリエンスをテストするために、アベイラビリティゾーンの障害をシミュレートします。"
kiteTranslationSourceHash: 4edf61e00926b1f0b2ee4b6fdbf4c633
---

## 概要

この再現可能な実験では、アベイラビリティゾーン（AZ）の障害をシミュレートし、重要なインフラストラクチャの障害に直面した際のアプリケーションのレジリエンスを実証します。AWS Fault Injection Simulator（FIS）および追加のAWSサービスを活用して、AZ全体が利用できなくなった場合にシステムが機能を維持する能力をテストします。

### 実験のセットアップ

EKSクラスターに関連するAuto Scaling Group（ASG）名を取得し、AZ障害をシミュレートするためのFIS実験テンプレートを作成します：

```bash wait=30
$ export ZONE_EXP_ID=$(aws fis create-experiment-template --cli-input-json '{"description":"publicdocument-azfailure","targets":{},"actions":{"azfailure":{"actionId":"aws:ssm:start-automation-execution","parameters":{"documentArn":"arn:aws:ssm:us-west-2::document/AWSResilienceHub-SimulateAzOutageInAsgTest_2020-07-23","documentParameters":"{\"AutoScalingGroupName\":\"'$ASG_NAME'\",\"CanaryAlarmName\":\"eks-workshop-canary-alarm\",\"AutomationAssumeRole\":\"'$FIS_ROLE_ARN'\",\"IsRollback\":\"false\",\"TestDurationInMinutes\":\"2\"}","maxDuration":"PT6M"}}},"stopConditions":[{"source":"none"}],"roleArn":"'$FIS_ROLE_ARN'","tags":{"ExperimentSuffix":"'$RANDOM_SUFFIX'"}}' --output json | jq -r '.experimentTemplate.id')
```

## 実験の実行

FIS実験を実行してAZ障害をシミュレートします：

```bash timeout=540
$ aws fis start-experiment --experiment-template-id $ZONE_EXP_ID --output json && timeout --preserve-status 480s ~/$SCRIPT_DIR/get-pods-by-az.sh

------us-west-2a------
  ip-10-42-100-4.us-west-2.compute.internal:
       ui-6dfb84cf67-h57sp   1/1   Running   0     12m
       ui-6dfb84cf67-h87h8   1/1   Running   0     12m
  ip-10-42-111-144.us-west-2.compute.internal:
       ui-6dfb84cf67-4xvmc   1/1   Running   0     11m
       ui-6dfb84cf67-crl2s   1/1   Running   0     6m23s

------us-west-2b------
  ip-10-42-141-243.us-west-2.compute.internal:
       No resources found in ui namespace.
  ip-10-42-150-255.us-west-2.compute.internal:
       No resources found in ui namespace.

------us-west-2c------
  ip-10-42-164-250.us-west-2.compute.internal:
       ui-6dfb84cf67-fl4hk   1/1   Running   0     11m
       ui-6dfb84cf67-mptkw   1/1   Running   0     11m
       ui-6dfb84cf67-zxnts   1/1   Running   0     6m27s
  ip-10-42-178-108.us-west-2.compute.internal:
       ui-6dfb84cf67-8vmcz   1/1   Running   0     6m28s
       ui-6dfb84cf67-wknc5   1/1   Running   0     12m
```

このコマンドは実験を開始し、シミュレートされたAZ障害の即時の影響を理解するために、8分間にわたって異なるノードとAZ全体のポッドの分布とステータスを監視します。

実験中、以下の一連のイベントが観察されるはずです：

1. 約3分後、AZゾーンに障害が発生します。
2. [Synthetic Canary](<https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#alarmsV2:alarm/eks-workshop-canary-alarm?~(alarmStateFilter~'ALARM)>) を見ると、状態が `In Alarm` に変化していることがわかります。
3. 実験開始から約4分後、他のAZにポッドが再表示されるのを確認できます。
4. 実験が完了すると、約7分後にAZが健全としてマークされ、EC2自動スケーリングアクションの結果として代替EC2インスタンスが起動され、各AZのインスタンス数は再び2になります。

この間、小売URLは利用可能な状態を維持し、EKSがAZ障害に対していかにレジリエントであるかを示します。

:::note
ノードとポッドの再配布を確認するには、次のコマンドを実行できます：

```bash timeout=900 wait=30
$ EXPECTED_NODES=6 && while true; do ready_nodes=$(kubectl get nodes --no-headers | grep " Ready" | wc -l); if [ "$ready_nodes" -eq "$EXPECTED_NODES" ]; then echo "All $EXPECTED_NODES expected nodes are ready."; echo "Listing the ready nodes:"; kubectl get nodes | grep " Ready"; break; else echo "Waiting for all $EXPECTED_NODES nodes to be ready... (Currently $ready_nodes are ready)"; sleep 10; fi; done
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

## 実験後の検証

実験後、シミュレートされたAZ障害にもかかわらず、アプリケーションが稼働していることを確認します：

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

このステップは、Kubernetesクラスターの高可用性構成の有効性と、重要なインフラストラクチャの障害時にサービスの継続性を維持する能力を確認します。

## 結論

AZ障害のシミュレーションは、EKSクラスターのレジリエンスとアプリケーションの高可用性設計の重要なテストを表しています。この実験を通じて、次の貴重な洞察が得られました：

1. マルチAZ展開戦略の有効性
2. 残りの健全なAZ全体でポッドを再スケジュールするKubernetesの能力
3. AZ障害がアプリケーションのパフォーマンスと可用性に与える影響
4. 主要なインフラストラクチャの問題を検出して対応するための監視および警告システムの効率性

この実験から得られる主な教訓は次のとおりです：

- 複数のAZにワークロードを分散することの重要性
- 適切なリソース割り当てとポッドアンチアフィニティルールの価値
- AZレベルの問題を迅速に検出できる堅牢な監視および警告システムの必要性
- 災害復旧およびビジネス継続計画の有効性

このような実験を定期的に実施することで、次のことが可能になります：

- インフラストラクチャとアプリケーションアーキテクチャの潜在的な弱点を特定する
- インシデント対応手順を改良する
- システムが大きな障害に耐える能力に自信を持つ
- アプリケーションのレジリエンスと信頼性を継続的に向上させる

真のレジリエンスは、単にそのような障害から生き残るだけでなく、重要なインフラストラクチャの障害に直面してもパフォーマンスとユーザーエクスペリエンスを維持することから来ることを覚えておいてください。この実験から得た洞察を使用して、アプリケーションの耐障害性をさらに強化し、すべてのシナリオでのシームレスな運用を確保しましょう。
