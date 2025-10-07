---
title: "HPAの設定"
sidebar_position: 10
kiteTranslationSourceHash: 7b21bff45ccd701d11889828ddeb5995
---

現在、クラスターには水平ポッド自動スケーリングを可能にするリソースはなく、以下のコマンドで確認できます：

```bash expectError=true
$ kubectl get hpa -A
No resources found
```

今回は`ui`サービスを利用し、CPU使用率に基づいてスケールさせます。まず最初に、`ui`のPod仕様を更新して、CPU `request`と`limit`の値を指定します。

```kustomization
modules/autoscaling/workloads/hpa/deployment.yaml
Deployment/ui
```

次に、HPAがワークロードをスケールする方法を決定するためのパラメータを定義する`HorizontalPodAutoscaler`リソースを作成する必要があります。

::yaml{file="manifests/modules/autoscaling/workloads/hpa/hpa.yaml" paths="spec.minReplicas,spec.maxReplicas,spec.scaleTargetRef,spec.targetCPUUtilizationPercentage"}

1. 常に少なくとも1つのレプリカを実行する
2. 4つ以上のレプリカにはスケールしない
3. HPAに`ui` Deploymentのレプリカ数を変更するよう指示する
4. CPU使用率のターゲットを80%に設定する

この設定を適用しましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/workloads/hpa
```
