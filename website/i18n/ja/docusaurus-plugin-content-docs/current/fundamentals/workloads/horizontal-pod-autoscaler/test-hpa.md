---
title: "負荷の生成"
sidebar_position: 20
kiteTranslationSourceHash: 5b60ea8540356c021bac58ab2e00ee3b
---

HPAが設定したポリシーに応じてスケールアウトする様子を観察するために、アプリケーションに負荷をかける必要があります。[hey](https://github.com/rakyll/hey)を使用してワークロードのホームページを呼び出すことで負荷を生成します。

以下のコマンドは、次のパラメータで負荷ジェネレータを実行します：

- 10ワーカーが同時に実行
- 各ワーカーが1秒あたり5クエリを送信
- 最大60分間実行

```bash hook=hpa-pod-scaleout hookTimeout=330
$ kubectl run load-generator \
  --image=williamyeh/hey:latest \
  --restart=Never -- -c 10 -q 5 -z 60m http://ui.ui.svc/home
```

アプリケーションへのリクエストが発生し始めたら、HPAリソースを監視して進捗状況を確認できます：

```bash test=false
$ kubectl get hpa ui -n ui --watch
NAME   REFERENCE       TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
ui     Deployment/ui   69%/80%   1         4         1          117m
ui     Deployment/ui   99%/80%   1         4         1          117m
ui     Deployment/ui   89%/80%   1         4         2          117m
ui     Deployment/ui   89%/80%   1         4         2          117m
ui     Deployment/ui   84%/80%   1         4         3          118m
ui     Deployment/ui   84%/80%   1         4         3          118m
```

オートスケーリングの動作に満足したら、`Ctrl+C`で監視を終了し、次のように負荷ジェネレータを停止できます：

```bash timeout=180
$ kubectl delete pod load-generator
```

負荷ジェネレータが終了すると、HPAは設定に基づいてレプリカ数をゆっくりと最小数まで減らしていきます。

