---
title: "負荷の生成"
sidebar_position: 20
tmdTranslationSourceHash: 'd1bf6954cff0fd4986118348039d7617'
---

設定したKEDA `ScaledObject`に応答してKEDAがDeploymentをスケールする様子を観察するには、アプリケーションに負荷を生成する必要があります。[hey](https://github.com/rakyll/hey)を使用してワークロードのホームページを呼び出すことで負荷を生成します。

以下のコマンドは、次の設定で負荷ジェネレーターを実行します:

- 3つのワーカーが同時に実行
- それぞれが1秒あたり5クエリを送信
- 最大10分間実行

```bash hook=keda-pod-scaleout hookTimeout=660 wait=300
$ export ALB_HOSTNAME=$(kubectl get ingress ui-auto -n ui -o yaml | yq .status.loadBalancer.ingress[0].hostname)
$ kubectl run load-generator \
  --image=williamyeh/hey:latest \
  --restart=Never -- -c 3 -q 5 -z 10m http://$ALB_HOSTNAME/home
```

`ScaledObject`に基づいて、KEDAはHPAリソースを作成し、HPAがワークロードをスケールするために必要なメトリクスを提供します。アプリケーションにリクエストが到達している状態で、HPAリソースを監視して進行状況を確認できます:

```bash test=false
$ kubectl get hpa keda-hpa-ui-hpa -n ui --watch
NAME              REFERENCE       TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-ui-hpa   Deployment/ui   7/100 (avg)   1         10        1          7m58s
keda-hpa-ui-hpa   Deployment/ui   778/100 (avg)   1         10        1          8m33s
keda-hpa-ui-hpa   Deployment/ui   194500m/100 (avg)   1         10        4          8m48s
keda-hpa-ui-hpa   Deployment/ui   97250m/100 (avg)    1         10        8          9m3s
keda-hpa-ui-hpa   Deployment/ui   625m/100 (avg)      1         10        8          9m18s
keda-hpa-ui-hpa   Deployment/ui   91500m/100 (avg)    1         10        8          9m33s
keda-hpa-ui-hpa   Deployment/ui   92125m/100 (avg)    1         10        8          9m48s
keda-hpa-ui-hpa   Deployment/ui   750m/100 (avg)      1         10        8          10m
keda-hpa-ui-hpa   Deployment/ui   102625m/100 (avg)   1         10        8          10m
keda-hpa-ui-hpa   Deployment/ui   113625m/100 (avg)   1         10        8          11m
keda-hpa-ui-hpa   Deployment/ui   90900m/100 (avg)    1         10        10         11m
keda-hpa-ui-hpa   Deployment/ui   91500m/100 (avg)    1         10        10         12m
```

オートスケーリングの動作に満足したら、`Ctrl+C`でwatchを終了し、次のように負荷ジェネレーターを停止できます:

```bash
$ kubectl delete pod load-generator --ignore-not-found
```

負荷ジェネレーターが終了すると、HPAは設定に基づいて最小レプリカ数までゆっくりと減らしていくことに注目してください。

CloudWatchコンソールで負荷テストの結果を確認することもできます:

<ConsoleButton url="https://console.aws.amazon.com/cloudwatch/home#metricsV2:graph=~();namespace=~'AWS*2fApplicationELB" service="cloudwatch" label="CloudWatchコンソールを開く"/>

お使いのアカウントでこのグラフを再現するには、CloudWatchメトリクスコンソールから、2つのメトリクスを追加し、それに応じてグラフを設定する必要があります:

1. **Metrics**の下で、クラスターと同じリージョンにいることを確認します。
1. **ApplicationELB > Per AppELB Metrics, per TG Metrics**の下で、`RequestCount`と`RequestCountPerTarget`を選択します。
1. **Graphed Metrics (2)**タブをクリックし、各メトリクスに対して以下を実行します:
    1. **Statistic**を`Average`から`Sum`に変更します。
    1. **Period**を`5 minutes`から`1 minute`に変更します。

結果から、最初はすべての負荷が単一のPodで処理されていましたが、KEDAがワークロードをスケールし始めると、リクエストはロードバランサーのターゲットグループで有効なターゲットになった追加のPodに分散されることがわかります。負荷ジェネレーターPodを10分間実行させた場合、このような結果が表示されます。

![Insights](/img/keda/keda-cloudwatch.png)

