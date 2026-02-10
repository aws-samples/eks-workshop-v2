---
title: Graviton (ARM) インスタンス
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service で AWS Graviton プロセッサを活用します。"
tmdTranslationSourceHash: 214be07bd59dc15643c95e4d9b35db3e
---

::required-time

:::tip 開始する前に
このセクションの環境を準備してください：

```bash timeout=600 wait=30
$ prepare-environment fundamentals/mng/graviton
```

:::

オンデマンドインスタンスやスポットインスタンスを使用しているかどうかに関わらず、AWSはEC2およびEC2バックのEKSマネージドノードグループ向けに3種類のプロセッサタイプを提供しています。お客様はIntel、AMD、ARM（AWS Graviton）プロセッサの中から選択できます。[AWS Gravitonプロセッサ](https://aws.amazon.com/ec2/graviton/)は、Amazon EC2で実行されるクラウドワークロードに最適な価格性能を提供するようAWSによって設計されています。

Gravitonベースのインスタンスは、[インスタンスタイプの命名規則](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#instance-type-names)のプロセッサファミリーセクションにある文字 `g` で識別できます。

![インスタンスタイプの命名規則](/docs/fundamentals/compute/managed-node-groups/graviton/instance-type-name.webp)

AWS Gravitonプロセッサは、[AWS Nitroシステム](https://aws.amazon.com/ec2/nitro/?p=pm&pd=graviton&z=3)上に構築されています。AWSはAWS Nitroシステムを構築して、ホストハードウェアのコンピューティングとメモリリソースのほぼすべてをインスタンスに提供します。これは、ハイパーバイザ機能と管理機能をホストから分離し、専用のハードウェアとソフトウェアにオフロードすることで実現されます。これにより、全体的なパフォーマンスが向上し、仮想マシンと同じ物理ホスト上でハイパーバイザソフトウェアを実行する従来の仮想化プラットフォームとは異なります。従来のプラットフォームでは、仮想マシンはホストのリソースを100％利用することができません。AWS Nitroシステムは、人気のあるLinuxオペレーティングシステムやAWSと独立系ソフトウェアベンダーの多くのアプリケーションとサービスによってサポートされています。

## Gravitonプロセッサを使用したマルチアーキテクチャ

:::info
AWS GravitonはARMに対応したコンテナイメージを必要とします。理想的にはマルチアーキテクチャ（ARM64とAMD64）に対応し、Gravitonとx86インスタンスタイプの両方との互換性を持つようにします。
:::

Gravitonプロセッサは、最大20％低いコスト、最大40％優れた価格性能、第5世代のx86ベースのインスタンスと比較して最大60％低いエネルギー消費を提供するインスタンスにより、マネージドノードグループのEKSエクスペリエンスを強化します。GravitonベースのEKSマネージドノードグループは、Gravitonプロセッサを搭載したEC2 Auto Scalingグループを起動します。

GravitonベースのインスタンスをEKSマネージドノードグループに追加すると、マルチアーキテクチャインフラストラクチャが導入され、アプリケーションが異なるCPU上で実行できるようにする必要があります。つまり、アプリケーションコードが異なる命令セットアーキテクチャ（ISA）実装で利用可能である必要があります。チームがGravitonベースのインスタンスへのアプリケーションの計画と移植を支援するためのさまざまなリソースがあります。有用なリソースとして[Graviton導入計画](https://pages.awscloud.com/rs/112-TZM-766/images/Graviton%20Challenge%20Plan.pdf)や[Graviton用ポーティングアドバイザー](https://github.com/aws/porting-advisor-for-graviton)をご確認ください。

![Gravitonプロセッサを使用したEKSマネージドノードグループ](/docs/fundamentals/compute/managed-node-groups/graviton/eks-graviton.webp)

:::tip
[リテールストアのサンプルWebアプリケーション](https://github.com/aws-containers/retail-store-sample-app/tree/main#application-architecture)アーキテクチャには、[x86-64とARM64の両方のCPUアーキテクチャ用に事前にビルドされたコンテナイメージ](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui)が含まれています。
:::

Gravitonインスタンスを使用する場合、ARM CPUアーキテクチャ用に構築されたコンテナのみがGravitonインスタンス上でスケジュールされるようにする必要があります。ここで、TaintとTolerationが役立ちます。

## TaintとToleration

Taintはノードのプロパティで、特定のPodを排除します。TolerationはPodに適用され、一致するTaintを持つノード上でのスケジューリングを許可します。TaintとTolerationは連携して、Podが不適切なノード上でスケジュールされないようにします。

Taintされたノードの構成は、特定のPodが特殊なハードウェア（GravitonベースのインスタンスやGPUが接続されたインスタンスなど）を持つ特定のノードグループ上でのみスケジュールされることを確認する必要があるシナリオで役立ちます。この実習では、マネージドノードグループにTaintを設定する方法と、Gravitonベースのプロセッサを実行しているTaintされたノードを使用するようにアプリケーションを設定する方法について学びます。
