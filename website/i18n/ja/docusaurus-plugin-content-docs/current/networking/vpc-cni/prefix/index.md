---
title: "プレフィックス委任"
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "プレフィックス委任を使用してAmazon Elastic Kubernetes Serviceでのポッド密度を増加させます。"
tmdTranslationSourceHash: 02babc010388ea9e399ee963c3b86193
---

::required-time

:::tip 始める前に
このセクションの環境を準備してください：

```bash timeout=300 wait=30
$ prepare-environment networking/prefix
```

:::

Amazon VPC CNIは[Amazon EC2ネットワークインターフェース](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-prefix-eni.html)にネットワークプレフィックスを割り当てることで、ノードで利用可能なIPアドレス数を増やし、ノードあたりのポッド密度を高めます。Amazon VPC CNIアドオンのバージョン1.9.0以降では、個々のセカンダリIPアドレスをネットワークインターフェースに割り当てる代わりにプレフィックスを割り当てるように構成できます。

プレフィックス割り当てモードでは、インスタンスタイプごとの弾性ネットワークインターフェースの最大数は同じままですが、nitro EC2インスタンスタイプのネットワークインターフェース上のスロットに個々のIPv4アドレスを割り当てる代わりに、/28（16個のIPアドレス）IPv4アドレスプレフィックスを割り当てるようにAmazon VPC CNIを構成できるようになりました。`ENABLE_PREFIX_DELEGATION`がtrueに設定されると、VPC CNIはENIに割り当てられたプレフィックスからPodにIPアドレスを割り当てます。

![サブネット](/docs/networking/vpc-cni/prefix/prefix_subnets.webp)

ワーカーノードの初期化中、VPC CNIはプライマリENIに1つ以上のプレフィックスを割り当てます。CNIはウォームプールを維持することで、より速いポッドの起動のためにプレフィックスを事前に割り当てます。

より多くのPodがスケジュールされるにつれて、既存のENIに追加のプレフィックスが要求されます。まず、VPC CNIは既存のENIに新しいプレフィックスを割り当てようとします。ENIが容量に達した場合、VPC CNIはノードに新しいENIを割り当てようとします。最大ENI制限（インスタンスタイプによって定義される）に達するまで、新しいENIが接続されます。新しいENIが接続されると、ipamdはウォームプール設定を維持するために必要な1つ以上のプレフィックスを割り当てます。

![プレフィックスフロー](/docs/networking/vpc-cni/prefix/prefix_flow.webp)

VPC CNIをプレフィックスモードで使用するための推奨事項のリストについては、[EKSベストプラクティスガイド](https://aws.github.io/aws-eks-best-practices/networking/prefix-mode/index_linux/)をご覧ください。

