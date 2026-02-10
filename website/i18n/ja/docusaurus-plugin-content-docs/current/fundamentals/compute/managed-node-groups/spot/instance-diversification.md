---
title: "インスタンスタイプの多様化"
sidebar_position: 10
tmdTranslationSourceHash: 1d7430c7f901a6a3774860c8be3d1e05
---

[Amazon EC2 Spot Instances](https://aws.amazon.com/ec2/spot/)は、AWS クラウドで利用可能な余剰コンピューティング容量をオンデマンド価格と比較して大幅な割引で提供します。EC2 が容量を必要とする場合、EC2 は2分間の通知でSpot インスタンスを中断することがあります。さまざまな耐障害性と柔軟性のあるアプリケーションにSpot インスタンスを使用できます。例としては、分析、コンテナ化されたワークロード、高性能コンピューティング(HPC)、ステートレスなウェブサーバー、レンダリング、CI/CD、その他のテストや開発ワークロードなどがあります。

Spot インスタンスを成功裏に導入するためのベストプラクティスの1つは、構成の一部として**Spot インスタンスの多様化**を実装することです。Spot インスタンスの多様化は、スケールアップと、Spot インスタンス終了通知を受け取る可能性のあるSpot インスタンスの交換の両方において、複数のSpot インスタンスプールから容量を調達するのに役立ちます。Spot インスタンスプールとは、同じインスタンスタイプ、オペレーティングシステム、アベイラビリティーゾーンを持つ未使用のEC2 インスタンスのセットです（例えば、`us-east-1a`の Red Hat Enterprise Linux 上の`m5.large`）。

### Spot インスタンスの多様化を用いたCluster Autoscaler

Cluster Autoscalerは、リソース不足によりクラスタ内で実行できないポッドがある場合（スケールアウト）や、一定期間利用されていないノードがクラスタ内にある場合（スケールイン）に、Kubernetes クラスタのサイズを自動的に調整するツールです。

:::tip
[Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)でSpot インスタンスを使用する際には、[考慮すべきことがいくつかあります](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)。重要な考慮事項の一つは、各Auto Scaling グループが、ほぼ同等の容量を提供するインスタンスタイプで構成されるべきだということです。Cluster Autoscalerは、ASG のMixed Instances Policy で提供される最初のオーバーライドに基づいて、Auto Scaling Group が提供するCPU、メモリ、およびGPU リソースを決定しようとします。そのようなオーバーライドが見つかった場合、最初に見つかったインスタンスタイプのみが使用されます。詳細については、[Mixed Instances Policies とSpot インスタンスの使用](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#Using-Mixed-Instances-Policies-and-Spot-Instances)を参照してください。
:::

Cluster Autoscalerを使用して動的に容量をスケールする際に、EKS とK8s クラスタにSpot 多様化のベストプラクティスを適用する場合、Cluster Autoscalerの予想される運用モードに準拠する方法で多様化を実装する必要があります。

以下の2つの戦略を用いてSpot インスタンスプールを多様化することができます：

- 異なるサイズの複数のノードグループを作成する。例えば、4 vCPUと16GB RAMのサイズのノードグループと、8 vCPUと32GB RAMのもう一つのノードグループ。
- ノードグループ内でインスタンスの多様化を実装する。同じvCPUとメモリ基準を満たす異なるSpot インスタンスプールから、インスタンスタイプとファミリーの混合を選択する。

このワークショップでは、クラスタノードグループには2 vCPUと4GiBのメモリを持つインスタンスタイプをプロビジョニングすると仮定します。

関連するインスタンスタイプとファミリーの選択を支援するために、**[amazon-ec2-instance-selector](https://github.com/aws/amazon-ec2-instance-selector)** を使用します。

EC2には350種類以上の異なるインスタンスタイプがあり、適切なインスタンスタイプの選択が難しくなる場合があります。それを容易にするために、CLIツールの `amazon-ec2-instance-selector` が、アプリケーションの実行に適合するインスタンスタイプの選択を支援します。コマンドラインインターフェースにCPU、メモリ、ネットワークパフォーマンスなどのリソース基準を渡すことで、利用可能な一致するインスタンスタイプを返します。

CLIツールはあなたのIDEに事前にインストールされています：

```bash
$ ec2-instance-selector --version
```

ec2-instance-selectorがインストールされたので、`ec2-instance-selector --help` を実行して、ワークロード要件に合うインスタンスの選択方法を理解できます。このワークショップでは、まず2 vCPUと4 GBのRAMという目標を満たすインスタンスのグループを取得する必要があります。

以下のコマンドを実行してインスタンスのリストを取得してください。

```bash
$ ec2-instance-selector --vcpus 2 --memory 4 --gpus 0 --current-generation \
  -a x86_64 --deny-list 't.*' --output table-wide
Instance Type   VCPUs   Mem (GiB)  Hypervisor  Current Gen  Hibernation Support  CPU Arch  Network Performance  ENIs    GPUs    GPU Mem (GiB)  GPU Info  On-Demand Price/Hr  Spot Price/Hr
-------------   -----   ---------  ----------  -----------  -------------------  --------  -------------------  ----    ----    -------------  --------  ------------------  -------------
c5.large        2       4          nitro       true         true                 x86_64    Up to 10 Gigabit     3       0       0              none      $0.085              $0.0344
c5a.large       2       4          nitro       true         false                x86_64    Up to 10 Gigabit     3       0       0              none      $0.077              $0.0275
c5ad.large      2       4          nitro       true         false                x86_64    Up to 10 Gigabit     3       0       0              none      $0.086              $0.0403
c5d.large       2       4          nitro       true         true                 x86_64    Up to 10 Gigabit     3       0       0              none      $0.096              $0.0468
c6a.large       2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.0765             $0.0313
c6i.large       2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.085              $0.0351
c6id.large      2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.1008             $0.0472
c6in.large      2       4          nitro       true         true                 x86_64    Up to 25 Gigabit     3       0       0              none      $0.1134             $0.0396
c7a.large       2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.10264            $0.0338
c7i-flex.large  2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.08479            $0.0419
c7i.large       2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.08925            $0.031
```

次のセクションでノードグループを定義する際に、これらのインスタンスを使用します。

内部的に、`ec2-instance-selector`は特定のリージョンに対して[DescribeInstanceTypes](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstanceTypes.html)を呼び出し、コマンドラインで選択された基準に基づいてインスタンスをフィルタリングしています。この場合、以下の基準に合うインスタンスをフィルタリングしました：

- GPUのないインスタンス
- x86_64アーキテクチャのインスタンス（A1やm6gなどのARMインスタンスは除外）
- 2 vCPUと4 GBのRAMを持つインスタンス
- 現行世代のインスタンス（第4世代以降）
- 正規表現`t.*`に一致しないインスタンス（バーストタイプのインスタンスをフィルタリング）

:::tip
ワークロードには、インスタンスタイプを選択する際に考慮すべき他の制約がある場合があります。例えば、**t2**および**t3**インスタンスタイプは[バースト可能インスタンス](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html)であり、CPU実行の決定性を必要とするCPUバウンドのワークロードには適切でない場合があります。m5**a**などのインスタンスは[AMDインスタンス](https://aws.amazon.com/ec2/amd/)で、ワークロードが数値的な違いに敏感な場合（例：金融リスク計算、産業シミュレーション）、これらのインスタンスタイプを混合することは適切でない場合があります。
:::
