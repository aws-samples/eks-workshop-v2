---
title: "クラスターオーバープロビジョニング"
sidebar_position: 50
kiteTranslationSourceHash: d62623f459247d11cec4ad17320371d7
---

Kubernetes の [AWS 向けクラスターオートスケーラー (CA)](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md) は、[EKS ノードグループ](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)の [AWS EC2 Auto Scaling グループ (ASG)](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html) を設定し、スケジューリング保留中のポッドがある場合にクラスター内のノードをスケールします。

ASG を変更してクラスターにノードを追加するこのプロセスは、本質的にポッドがスケジュール可能になるまでの時間を追加します。例えば、前のセクションでは、アプリケーションのスケーリング中に作成されたポッドが利用可能になるまでに数分かかったことに気づいたかもしれません。

この問題を解決するためのアプローチはいくつかあります。この実習では、プレースホルダーとして使用される優先度の低いポッドを実行する追加のノードでクラスターを「オーバープロビジョニング」することで問題に対処します。これらの優先度の低いポッドは、重要なアプリケーションポッドがデプロイされると退避されます。プレースホルダーポッドは、CPUとメモリリソースを予約するだけでなく、[AWS VPC Container Network Interface - CNI](https://docs.aws.amazon.com/eks/latest/userguide/pod-networking.html) から割り当てられた IP アドレスも確保します。
