---
title: "クラスタオートスケーラー (CA)"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "クラスタオートスケーラーでAmazon Elastic Kubernetes Serviceのコンピュートを自動的に管理します。"
kiteTranslationSourceHash: 52a7905108794621ca7ad7829dd71081
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment autoscaling/compute/cluster-autoscaler
```

これにより、ラボ環境に以下の変更が適用されます：

- cluster-autoscalerで使用されるIAMロールを作成します

これらの変更を適用するTerraformコードは[こちら](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/compute/cluster-autoscaler/.workshop/terraform)で確認できます。

:::

このラボでは、[Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler)を見ていきます。これは、すべてのPodが不要なノードなしで実行できる場所を確保できるように、Kubernetesクラスタのサイズを自動的に調整するコンポーネントです。Cluster Autoscalerは、基盤となるクラスタインフラストラクチャが弾力的でスケーラブルであり、変化するワークロードの需要に対応できるようにするための優れたツールです。

Kubernetes Cluster Autoscalerは、次のいずれかの条件が真である場合に、Kubernetesクラスタのサイズを自動的に調整します：

1. リソースが不足しているため、クラスタ内でPodを実行できない場合。
2. クラスタ内のノードが長期間にわたって十分に活用されておらず、そのPodを他の既存のノードに配置できる場合。

AWS向けのCluster Autoscalerは、[Auto Scaling groupsとの統合](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws)を提供しています。

このラボ演習では、Cluster AutoscalerをEKSクラスタに適用し、ワークロードをスケールアップしたときにどのような動作をするかを確認します。
