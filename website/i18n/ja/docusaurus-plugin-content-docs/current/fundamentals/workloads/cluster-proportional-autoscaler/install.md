---
title: "CoreDNSのオートスケーリング"
date: 2022-07-21T00:00:00-03:00
sidebar_position: 2
tmdTranslationSourceHash: 43f85cae9190a6925d7ae670d98ded21
---

CoreDNSはKubernetesのデフォルトのDNSサービスであり、`k8s-app=kube-dns`というラベルを持つPodで実行されています。このラボ演習では、クラスターのスケジュール可能なノードとコアの数に基づいてCoreDNSをスケールします。Cluster Proportional AutoscalerがCoreDNSのレプリカ数を調整します。

:::info

Amazon EKSは[EKSアドオンを通じてCoreDNSを自動的にスケールする機能](https://docs.aws.amazon.com/eks/latest/userguide/coredns-autoscaling.html)を提供しており、これが本番環境での推奨パスです。このラボで取り上げる内容は教育目的です。

:::

まず、Helmチャートを使用してCPAをインストールしましょう。CPAを設定するために次の`values.yaml`ファイルを使用します：

::yaml{file="manifests/modules/autoscaling/workloads/cpa/values.yaml" paths="options.target,config.linear.nodesPerReplica,config.linear.min,config.linear.max"}

この設定では：

1. デプロイメント`coredns`をターゲットにします
2. クラスター内のワーカーノード2台ごとにレプリカを1つ追加します
3. 常に少なくとも2つのレプリカを実行します
4. 6つ以上のレプリカにはスケールしません

:::caution

上記の設定はCoreDNSを自動的にスケールするためのベストプラクティスとは見なされるべきではなく、ワークショップの目的のために実証しやすい例です。

:::

チャートをインストールしましょう：

```bash
$ helm repo add cluster-proportional-autoscaler https://kubernetes-sigs.github.io/cluster-proportional-autoscaler
$ helm upgrade --install cluster-proportional-autoscaler cluster-proportional-autoscaler/cluster-proportional-autoscaler \
  --namespace kube-system \
  --version "${CPA_CHART_VERSION}" \
  --set "image.tag=v${CPA_VERSION}" \
  --values ~/environment/eks-workshop/modules/autoscaling/workloads/cpa/values.yaml \
  --wait
NAME: cluster-proportional-autoscaler
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

これにより、`kube-system`名前空間に`Deployment`が作成されます。確認してみましょう：

```bash
$ kubectl get deployment cluster-proportional-autoscaler -n kube-system
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
cluster-proportional-autoscaler   1/1     1            1           92s
```
