---
title: "アプリケーションのオートスケーリング"
chapter: true
sidebar_position: 80
description: "KEDAを使用してAmazon Elastic Kubernetes Service上のワークロードを自動的にスケールする"
tmdTranslationSourceHash: 'd769f5905db18fbbe1dcf4ebd3b78bf5'
---

:::tip 事前に設定されている内容
Amazon EKS Auto Modeクラスターが作成された後、KEDA Operator用のIAMロールが設定されています
:::

オートスケーリングは、ワークロードを監視し、安定した予測可能なパフォーマンスを維持しながら、コストを最適化するために容量を自動的に調整します。Kubernetesを使用する場合、自動的にスケールするために使用できる主な関連メカニズムは2つあります：

- **コンピュート：** Podがスケールされると、Kubernetesクラスター内の基盤となるコンピュートも、Podを実行するために使用されるワーカーノードの数またはサイズを調整することで適応する必要があります。
- **Pod：** Podはkubernetesクラスター内でワークロードを実行するために使用されるため、ワークロードのスケーリングは主に、特定のアプリケーションへの負荷の変化などのシナリオに応じて、Podを水平または垂直にスケールすることによって行われます。

このラボでは、[Kubernetes Event-Driven Autoscaler (KEDA)](https://keda.sh/)を使用してdeployment内のPodをスケールする方法を見ていきます。この目的のために使用できる別のオプションとして、Horizontal Pod Autoscaler (HPA)があり、平均CPU使用率に基づいてPodを水平にスケールするために使用できます。しかし、ワークロードは外部イベントやメトリクスに基づいてスケールする必要がある場合があります。そのため、KEDAは、Amazon SQSのキューの長さやCloudWatchの他のメトリクスなど、さまざまなイベントソースからのイベントに基づいてワークロードをスケールする機能を提供します。KEDAは、さまざまなメトリクスシステム、データベース、メッセージングシステムなどに対応する60以上の[scaler](https://keda.sh/docs/scalers/)をサポートしています。

KEDAは、Helmチャートを使用してKubernetesクラスターにデプロイできる軽量のワークロードです。KEDAは、Horizontal Pod AutoscalerのようなKubernetesの標準コンポーネントと連携して、DeploymentまたはStatefulSetをスケールします。KEDAを使用すると、これらのさまざまなイベントソースでスケールしたいワークロードを選択的に選択できます。

