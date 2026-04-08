---
title: "Pod障害のシミュレーション"
sidebar_position: 110
description: "ChaosMeshを使用して環境内でPod障害をシミュレーションし、アプリケーションの回復力をテストします。"
tmdTranslationSourceHash: 3fe01b7fd1a8c473e211b22fd0decc5a
---

## 概要

このラボでは、Kubernetes環境内でPod障害をシミュレーションして、システムがどのように応答し回復するかを観察します。この実験は、Podが予期せず障害が発生した場合に、アプリケーションの回復力を逆境下でテストするように設計されています。

`pod-failure.sh`スクリプトは、KubernetesのパワフルなカオスエンジニアリングプラットフォームであるChaos Meshを使用してPod障害をシミュレーションします。この制御された実験によって、以下が可能になります：

1. Pod障害に対するシステムの即時対応を観察する
2. 自動回復プロセスを監視する
3. シミュレーションされた障害にもかかわらず、アプリケーションが利用可能であることを確認する

この実験は繰り返し実行可能であり、一貫した動作を確認したり、さまざまなシナリオや構成をテストしたりすることができます。これは私たちが使用するスクリプトです：

```file
manifests/modules/observability/resiliency/scripts/pod-failure.sh
```

## 実験の実行

### ステップ1：初期Pod状態の確認

まず、`ui`名前空間内のPodの初期状態を確認しましょう：

```bash
$ kubectl get pods -n ui -o wide
```

次のような出力が表示されるはずです：

```text
NAME                  READY   STATUS    RESTARTS   AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-6dfb84cf67-44hc9   1/1     Running   0          46s   10.42.121.37    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-6d5lq   1/1     Running   0          46s   10.42.121.36    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-hqccq   1/1     Running   0          46s   10.42.154.216   ip-10-42-146-130.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-qqltz   1/1     Running   0          46s   10.42.185.149   ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-rzbvl   1/1     Running   0          46s   10.42.188.96    ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
```

すべてのPodが同様の開始時間（AGE列に表示）を持っていることに注意してください。

### ステップ2：Pod障害のシミュレーション

次に、Pod障害をシミュレーションしましょう：

```bash
$ ~/$SCRIPT_DIR/pod-failure.sh
```

このスクリプトはChaos Meshを使用してPodの1つを終了させます。

### ステップ3：回復の観察

Kubernetesが障害を検出して回復を開始するのを待つために数秒待ってから、もう一度Pod状態を確認します：

```bash timeout=5
$ kubectl get pods -n ui -o wide
```

次のような出力が表示されるはずです：

```text
NAME                  READY   STATUS    RESTARTS   AGE     IP              NODE                                          NOMINATED NODE   READINESS GATES
ui-6dfb84cf67-44hc9   1/1     Running   0          2m57s   10.42.121.37    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-6d5lq   1/1     Running   0          2m57s   10.42.121.36    ip-10-42-119-94.us-west-2.compute.internal    <none>           <none>
ui-6dfb84cf67-ghp5z   1/1     Running   0          6s      10.42.185.150   ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-hqccq   1/1     Running   0          2m57s   10.42.154.216   ip-10-42-146-130.us-west-2.compute.internal   <none>           <none>
ui-6dfb84cf67-rzbvl   1/1     Running   0          2m57s   10.42.188.96    ip-10-42-176-213.us-west-2.compute.internal   <none>           <none>
[ec2-user@bc44085aafa9 environment]$
```

Podの1つ（この例では `ui-6dfb84cf67-ghp5z`）のAGE値が非常に低いことに注意してください。これはシミュレーションによって終了したPodを置き換えるために、Kubernetesが自動的に作成したPodです。

これにより、`ui`名前空間内の各Podの状態、IPアドレス、およびノードが表示されます。

## 小売店の可用性の確認

この実験の重要な側面は、Pod障害および回復プロセス全体を通じて小売店アプリケーションが動作し続けることを確認することです。小売店の可用性を確認するには、次のコマンドを使用してストアのURLを取得しアクセスします：

```bash timeout=900
$ wait-for-lb $(kubectl get ingress -n ui -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

Waiting for k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com...
You can now access http://k8s-ui-ui-5ddc3ba496-721427594.us-west-2.elb.amazonaws.com
```

準備ができたら、このURLから小売店にアクセスして、シミュレーションされたPod障害にもかかわらず、まだ正しく機能していることを確認できます。

## 結論

このPod障害シミュレーションは、Kubernetesベースのアプリケーションの回復力を示しています。意図的にPodに障害を発生させることで、以下のことを観察できます：

1. システムが障害をすばやく検出する能力
2. KubernetesによるDeploymentまたはStatefulSetの障害が発生したPodの自動再スケジューリングと回復
3. Pod障害中のアプリケーションの継続的な可用性

Podに障害が発生した場合でも小売店は運用を継続し、Kubernetesセットアップの高可用性と障害耐性を示します。この実験は、アプリケーションの回復力を検証するのに役立ち、さまざまなシナリオや、インフラストラクチャに変更を加えた後で一貫した動作を確保するために、必要に応じて繰り返すことができます。

このようなカオスエンジニアリング実験を定期的に実行することで、システムがさまざまな種類の障害に耐え回復する能力に自信を持つことができ、最終的にはより堅牢で信頼性の高いアプリケーションにつながります。
