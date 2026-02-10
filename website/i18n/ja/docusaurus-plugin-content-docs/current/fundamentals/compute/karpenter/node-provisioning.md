---
title: "自動ノードプロビジョニング"
sidebar_position: 40
tmdTranslationSourceHash: a5d1f58dfb782facf8b68b3bfbaee988
---

スケジュールできないポッドのニーズに応じて、Karpenterが適切なサイズのEC2インスタンスを動的にプロビジョニングする方法を確認していきましょう。これにより、EKSクラスター内の未使用のコンピュートリソースを削減することができます。

前のセクションで作成したNodePoolでは、Karpenterが使用できる特定のインスタンスタイプを指定しました。これらのインスタンスタイプを見てみましょう：

| Instance Type | vCPU | Memory | Price |
| ------------- | ---- | ------ | ----- |
| `c5.large`    | 2    | 4GB    | +     |
| `m5.large`    | 2    | 8GB    | ++    |
| `r5.large`    | 2    | 16GB   | +++   |
| `m5.xlarge`   | 4    | 16GB   | ++++  |

いくつかのPodを作成して、Karpenterがどのように適応するか見てみましょう。現在、Karpenterによって管理されているノードはありません：

```bash
$ kubectl get node -l type=karpenter
No resources found
```

Karpenterがスケールアウトするきっかけとなる以下のDeploymentを使用します：

::yaml{file="manifests/modules/autoscaling/compute/karpenter/scale/deployment.yaml" paths="spec.replicas,spec.template.spec.nodeSelector,spec.template.spec.containers.0.image,spec.template.spec.containers.0.resources"}

1. 初めは実行するレプリカを0に指定し、後でスケールアップします
2. NodePoolに一致するノードセレクタを使用して、Karpenterによってプロビジョニングされた容量にポッドをスケジュールする必要があります
3. シンプルな`pause`コンテナイメージを使用します
4. 各ポッドに`1Gi`のメモリをリクエストします

:::info pauseコンテナとは？
この例では、以下のイメージを使用していることがわかります：

`public.ecr.aws/eks-distro/kubernetes/pause`

これは実質的にリソースを消費せず、素早く起動する小さなコンテナで、スケーリングシナリオのデモに最適です。このラボの多くの例でこれを使用します。
:::

このデプロイメントを適用しましょう：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/karpenter/scale
deployment.apps/inflate created
```

ここで、Karpenterが最適化された決定を行うことを実証するために、このデプロイメントを意図的にスケールしてみましょう。1Giのメモリをリクエストしているので、デプロイメントを5レプリカにスケールすると、合計5Giのメモリをリクエストすることになります。

進める前に、上の表からどのインスタンスをKarpenterがプロビジョニングすると思いますか？どのインスタンスタイプが望ましいでしょうか？

デプロイメントをスケールします：

```bash
$ kubectl scale -n other deployment/inflate --replicas 5
```

この操作は1つ以上の新しいEC2インスタンスを作成するため、しばらく時間がかかります。`kubectl`を使用して完了するまで待つことができます：

```bash hook=karpenter-deployment timeout=200
$ kubectl rollout status -n other deployment/inflate --timeout=180s
```

すべてのPodが実行されたら、どのインスタンスタイプが選択されたか確認してみましょう：

```bash
$ kubectl logs -l app.kubernetes.io/instance=karpenter -n karpenter | grep 'launched nodeclaim' | jq '.'
```

インスタンスタイプと購入オプションを示す出力が表示されるはずです：

```json
{
  "level": "INFO",
  "time": "2023-11-16T22:32:00.413Z",
  "logger": "controller.nodeclaim.lifecycle",
  "message": "launched nodeclaim",
  "commit": "1072d3b",
  "nodeclaim": "default-xxm79",
  "nodepool": "default",
  "provider-id": "aws:///us-west-2a/i-0bb8a7e6111d45591",
  # HIGHLIGHT
  "instance-type": "m5.large",
  "zone": "us-west-2a",
  # HIGHLIGHT
  "capacity-type": "on-demand",
  "allocatable": {
    "cpu": "1930m",
    "ephemeral-storage": "17Gi",
    "memory": "6903Mi",
    "pods": "29",
    "vpc.amazonaws.com/pod-eni": "9"
  }
}
```

スケジュールしたポッドは8GBのメモリを持つEC2インスタンスにうまく収まり、Karpenterはオンデマンドインスタンスに対して常に最も低価格のインスタンスタイプを優先するため、`m5.large`を選択します。

:::info
最も安価なインスタンスタイプ以外が選択される場合もあります。例えば、最も安価なインスタンスタイプが作業中のリージョンで利用可能な容量がない場合などです
:::

Karpenterによってノードに追加されたメタデータも確認できます：

```bash
$ kubectl get node -l type=karpenter -o jsonpath='{.items[0].metadata.labels}' | jq '.'
```

この出力には、例えばインスタンスタイプ、購入オプション、アベイラビリティゾーンなど、設定されている様々なラベルが表示されます：

```json
{
  "beta.kubernetes.io/arch": "amd64",
  "beta.kubernetes.io/instance-type": "m5.large",
  "beta.kubernetes.io/os": "linux",
  "failure-domain.beta.kubernetes.io/region": "us-west-2",
  "failure-domain.beta.kubernetes.io/zone": "us-west-2a",
  "k8s.io/cloud-provider-aws": "1911afb91fc78905500a801c7b5ae731",
  "karpenter.k8s.aws/instance-category": "m",
  "karpenter.k8s.aws/instance-cpu": "2",
  "karpenter.k8s.aws/instance-family": "m5",
  "karpenter.k8s.aws/instance-generation": "5",
  "karpenter.k8s.aws/instance-hypervisor": "nitro",
  "karpenter.k8s.aws/instance-memory": "8192",
  "karpenter.k8s.aws/instance-pods": "29",
  "karpenter.k8s.aws/instance-size": "large",
  "karpenter.sh/capacity-type": "on-demand",
  "karpenter.sh/initialized": "true",
  "karpenter.sh/provisioner-name": "default",
  "kubernetes.io/arch": "amd64",
  "kubernetes.io/hostname": "ip-100-64-10-200.us-west-2.compute.internal",
  "kubernetes.io/os": "linux",
  "node.kubernetes.io/instance-type": "m5.large",
  "topology.ebs.csi.aws.com/zone": "us-west-2a",
  "topology.kubernetes.io/region": "us-west-2",
  "topology.kubernetes.io/zone": "us-west-2a",
  "type": "karpenter",
  "vpc.amazonaws.com/has-trunk-attached": "true"
}
```

この単純な例は、Karpenterがワークロードのリソース要件に基づいて適切なインスタンスタイプを動的に選択できることを示しています。これは、Cluster Autoscalerのようなノードプール指向のモデルとは根本的に異なります。そのようなモデルでは、単一のノードグループ内のインスタンスタイプはCPUとメモリの特性が一貫している必要があります。
