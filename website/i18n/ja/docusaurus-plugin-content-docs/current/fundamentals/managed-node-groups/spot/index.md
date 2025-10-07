---
title: Spot インスタンス
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service で Amazon EC2 Spot インスタンスを利用して割引を受けましょう。"
kiteTranslationSourceHash: d5e3f66529acf6abfa7a606cf0b804d3
---

::required-time

:::tip 始める前に
このセクションの環境を準備しましょう。

```bash timeout=300 wait=30
$ prepare-environment fundamentals/mng/spot
```

:::

私たちの既存のコンピュートノードはすべてオンデマンドキャパシティを使用しています。しかし、EKS ワークロードを実行するための複数の「[購入オプション](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-purchasing-options.html)」が EC2 のお客様に提供されています。

Spot インスタンスは、オンデマンド価格よりも低価格で利用可能な予備の EC2 キャパシティを使用します。Spot インスタンスを使用すると、未使用の EC2 インスタンスを大幅な割引で要求できるため、Amazon EC2 のコストを大幅に削減できます。Spot インスタンスの時間単位の料金は Spot 価格と呼ばれます。各インスタンスタイプの Spot 価格は、アベイラビリティゾーンごとに Amazon EC2 によって設定され、Spot インスタンスの長期的な需要と供給に基づいて徐々に調整されます。キャパシティが利用可能な場合、Spot インスタンスが実行されます。

Spot インスタンスは、ステートレスで、耐障害性があり、柔軟なアプリケーションに適しています。これには、バッチ処理や機械学習トレーニングのワークロード、Apache Spark のようなビッグデータ ETL、キュー処理アプリケーション、ステートレスな API エンドポイントなどが含まれます。Spot はスペア Amazon EC2 キャパシティであり、時間とともに変化する可能性があるため、中断に対して耐性のあるワークロードに Spot キャパシティを使用することをお勧めします。より具体的には、必要なキャパシティが利用できない期間があっても耐えられるワークロードに Spot キャパシティが適しています。

このラボでは、EKS マネージドノードグループで EC2 Spot キャパシティをどのように活用できるかを見ていきます。

