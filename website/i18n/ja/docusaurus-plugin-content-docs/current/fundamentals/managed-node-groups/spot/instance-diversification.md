---
title: "インスタンスタイプの多様化"
sidebar_position: 10
kiteTranslationSourceHash: 1d7430c7f901a6a3774860c8be3d1e05
---

[Amazon EC2 スポットインスタンス](https://aws.amazon.com/ec2/spot/)は、AWS クラウドで利用可能な余剰コンピューティング容量をオンデマンド価格と比較して大幅な割引で提供します。EC2 は容量が必要になると 2 分間の通知でスポットインスタンスを中断することがあります。スポットインスタンスは、さまざまな耐障害性と柔軟性のあるアプリケーションに使用できます。例としては、分析、コンテナ化されたワークロード、高性能コンピューティング（HPC）、ステートレスなウェブサーバー、レンダリング、CI/CD、その他のテストと開発ワークロードがあります。

スポットインスタンスを成功裏に採用するためのベストプラクティスの 1 つは、構成の一部として**スポットインスタンス多様化**を実装することです。スポットインスタンス多様化は、スケールアップと、スポットインスタンス終了通知を受ける可能性のあるスポットインスタンスの交換の両方について、複数のスポットインスタンスプールから容量を調達するのに役立ちます。スポットインスタンスプールは、同じインスタンスタイプ、オペレーティングシステム、アベイラビリティーゾーンを持つ未使用の EC2 インスタンスの集合です（例えば、`us-east-1a` の Red Hat Enterprise Linux 上の `m5.large`）。

### スポットインスタンス多様化によるクラスターオートスケーラー

クラスターオートスケーラーは、リソース不足によりクラスター内で実行できないポッドがある場合（スケールアウト）、または一定期間活用されていないノードがクラスター内にある場合（スケールイン）に、Kubernetes クラスターのサイズを自動調整するツールです。

:::tip
[クラスターオートスケーラー](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)でスポットインスタンスを使用する場合は、[考慮すべきこと](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)がいくつかあります。重要な考慮事項の 1 つは、各 Auto Scaling グループが約等しい容量を提供するインスタンスタイプで構成されるべきということです。クラスターオートスケーラーは、Auto Scaling グループの Mixed Instances Policy で提供される最初のオーバーライドに基づいて、Auto Scaling グループが提供する CPU、メモリ、および GPU リソースを決定しようとします。そのようなオーバーライドが見つかった場合、最初に見つかったインスタンスタイプのみが使用されます。詳細については、[Mixed Instances Policies とスポットインスタンスの使用](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#Using-Mixed-Instances-Policies-and-Spot-Instances)を参照してください。
:::

クラスターオートスケーラーを使用して容量を動的にスケールしながら、EKS と K8s クラスターにスポット多様化のベストプラクティスを適用する場合、クラスターオートスケーラーの想定される操作モードに準拠する方法で多様化を実装する必要があります。

次の 2 つの戦略を使用してスポットインスタンスプールを多様化できます：

- サイズの異なる複数のノードグループを作成する。例えば、4 vCPU と 16GB RAM のサイズのノードグループと、8 vCPU と 32GB RAM のサイズの別のノードグループ。
- ノードグループ内でインスタンスの多様化を実装し、同じ vCPU とメモリの基準を満たす異なるインスタンスタイプとファミリーを異なるスポットインスタンスプールから選択する。

このワークショップでは、クラスターノードグループは 2 vCPU と 4GiB のメモリを持つインスタンスタイプでプロビジョニングされるべきと仮定します。

関連するインスタンスタイプとファミリーを選択するために **[amazon-ec2-instance-selector](https://github.com/aws/amazon-ec2-instance-selector)** を使用します。

EC2 には 350 以上の異なるインスタンスタイプがあり、適切なインスタンスタイプを選択するプロセスが難しくなる可能性があります。これを容易にするために、CLI ツールの `amazon-ec2-instance-selector` が、アプリケーションを実行するための互換性のあるインスタンスタイプを選択するのに役立ちます。コマンドラインインターフェースには、CPU、メモリ、ネットワークパフォーマンスなどのリソース条件を渡すことができ、利用可能な一致するインスタンスタイプを返します。

CLI ツールは IDE に事前にインストールされています：

```bash
$ ec2-instance-selector --version
```

ec2-instance-selector がインストールされたので、`ec2-instance-selector --help` を実行して、ワークロード要件に合ったインスタンスを選択するためにどのように使用できるかを理解できます。このワークショップの目的では、まず 2 vCPU と 4 GB の RAM という目標を満たすインスタンスのグループを取得する必要があります。

次のコマンドを実行してインスタンスのリストを取得します。

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

次のセクションでノードグループを定義するときに、これらのインスタンスを使用します。

内部的に `ec2-instance-selector` は、特定のリージョンに対する [DescribeInstanceTypes](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstanceTypes.html) への呼び出しを行い、コマンドラインで選択した条件に基づいてインスタンスをフィルタリングしています。この場合、次の条件を満たすインスタンスをフィルタリングしました：

- GPU なしのインスタンス
- x86_64 アーキテクチャのインスタンス（A1 や m6g インスタンスなどの ARM インスタンスはなし）
- 2 vCPU と 4 GB の RAM を持つインスタンス
- 現世代のインスタンス（第 4 世代以降）
- バーストタイプのインスタンスをフィルタリングするための正規表現 `t.*` に一致しないインスタンス

:::tip
ワークロードには、インスタンスタイプを選択する際に考慮すべき他の制約がある場合があります。例えば、**t2** と **t3** インスタンスタイプは [バーストタイプのインスタンス](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html) であり、CPU バウンドのワークロードや CPU 実行の決定性を必要とするワークロードには適切でない場合があります。m5**a** などのインスタンスは [AMD インスタンス](https://aws.amazon.com/ec2/amd/) であり、数値的な差異に敏感なワークロード（例：金融リスク計算、産業シミュレーション）では、これらのインスタンスタイプを混合することは適切でない場合があります。
:::
