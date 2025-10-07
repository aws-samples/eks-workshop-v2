---
title: "CoreDNS ポッドの確認"
sidebar_position: 52
kiteTranslationSourceHash: 49b317983e950e56300ddbf081a229fa
---

EKSクラスターでは、CoreDNSポッドがDNS解決を処理します。これらのポッドが正しく実行されていることを確認しましょう。

### ステップ1 - ポッドのステータスを確認する

まず、kube-system名前空間のCoreDNSポッドを確認します：

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
CoreDNS-6fdb8f5699-dq7xw   0/1     Pending   0          42s
CoreDNS-6fdb8f5699-z57jw   0/1     Pending   0          42s
```

CoreDNSポッドが実行されていないことが確認できます。これがクラスターでのDNS解決の問題を明確に説明しています。

:::info
ポッドがPending状態であることは、それらがどのノードにもスケジュールされていないことを示しています。
:::

### ステップ2 - ポッドのイベントを確認する

これらのポッドに関連するイベントを調査するため、その説明を確認しましょう：

```bash timeout=30
$ kubectl describe po -l k8s-app=kube-dns -n kube-system | sed -n '/Events:/,/^$/p'

Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  29s   default-scheduler  0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

警告メッセージは、ノードラベルとCoreDNSポッドのノードセレクタ/アフィニティの間に不一致があることを示しています。

### ステップ3 - ノード選択の確認

CoreDNSポッドのノードセレクタを調べてみましょう：

```bash timeout=30
$ kubectl get deployment coredns -n kube-system -o jsonpath='{.spec.template.spec.nodeSelector}' | jq
{
  "workshop-default": "no"
}
```

ワーカーノードのラベルを確認します：

```bash timeout=30
$ kubectl get node -o jsonpath='{.items[0].metadata.labels}' | jq
{
  "alpha.eksctl.io/cluster-name": "eks-workshop",
  "alpha.eksctl.io/nodegroup-name": "default",
  "beta.kubernetes.io/arch": "amd64",
  "beta.kubernetes.io/instance-type": "m5.large",
  "beta.kubernetes.io/os": "linux",
  "eks.amazonaws.com/capacityType": "ON_DEMAND",
  "eks.amazonaws.com/nodegroup": "default",
  "eks.amazonaws.com/nodegroup-image": "ami-07fdc65a0c344a252",
  "eks.amazonaws.com/sourceLaunchTemplateId": "lt-0f7c7c3c9cb770aaa",
  "eks.amazonaws.com/sourceLaunchTemplateVersion": "1",
  "failure-domain.beta.kubernetes.io/region": "us-west-2",
  "failure-domain.beta.kubernetes.io/zone": "us-west-2a",
  "k8s.io/cloud-provider-aws": "b2c4991f4c3acb5b142be2a5d455731a",
  "kubernetes.io/arch": "amd64",
  "kubernetes.io/hostname": "ip-10-42-100-65.us-west-2.compute.internal",
  "kubernetes.io/os": "linux",
  "node.kubernetes.io/instance-type": "m5.large",
  "topology.k8s.aws/zone-id": "usw2-az1",
  "topology.kubernetes.io/region": "us-west-2",
  "topology.kubernetes.io/zone": "us-west-2a",
  "workshop-default": "yes"
}
```

CoreDNSポッドは`workshop-default: no`ラベルを持つノードを必要としますが、ノードには`workshop-default: yes`とラベル付けされています。

:::info
ポッドのyamlマニフェストには、ノードへのポッドスケジューリングに影響を与えるさまざまなオプションがあります。その他のパラメータには、アフィニティ、アンチアフィニティ、ポッドトポロジースプレッド制約が含まれます。詳細については[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)を参照してください。
:::

### 根本原因

本番環境では、チームはしばしばCoreDNSにノードセレクタを使用して、これらのポッドをクラスターシステムコンポーネント専用のノードで実行します。ただし、セレクタがノードラベルと一致しない場合、ポッドはPending状態のままになります。

この場合、CoreDNSアドオンは既存のノードと一致しないノードセレクタで構成されており、ポッドが実行されるのを妨げています。

### 解決策

この問題を修正するために、CoreDNSアドオンをデフォルト設定に更新し、nodeSelector要件を削除します：

```bash timeout=180
$ aws eks update-addon \
    --cluster-name $EKS_CLUSTER_NAME \
    --region $AWS_REGION \
    --addon-name coredns \
    --resolve-conflicts OVERWRITE \
    --configuration-values '{}'
{
    "update": {
        "id": "b3e7d81c-112a-33ea-bb28-1b1052bc3969",
        "status": "InProgress",
        "type": "AddonUpdate",
        "params": [
            {
                "type": "ResolveConflicts",
                "value": "OVERWRITE"
            },
            {
                "type": "ConfigurationValues",
                "value": "{}"
            }
        ],
        "createdAt": "20XX-XX-09T16:25:15.885000-05:00",
        "errors": []
    }
}
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name coredns
```

そして、CoreDNSポッドが現在実行されていることを確認します：

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
CoreDNS-7f6dd6865f-7qcjr   1/1     Running   0          100s
CoreDNS-7f6dd6865f-kxw2x   1/1     Running   0          100s
```

最後に、CoreDNSログをチェックして、アプリケーションがエラーなく実行されていることを確認します：

```bash timeout=30
$ kubectl logs -l k8s-app=kube-dns -n kube-system
.:53
[INFO] plugin/reload: Running configuration SHA512 = 8a7d59126e7f114ab49c6d2613be93d8ef7d408af8ee61a710210843dc409f03133727e38f64469d9bb180f396c84ebf48a42bde3b3769730865ca9df5eb281c
CoreDNS-1.11.1
linux/amd64, go1.21.5, e9c721d80
.:53
[INFO] plugin/reload: Running configuration SHA512 = 8a7d59126e7f114ab49c6d2613be93d8ef7d408af8ee61a710210843dc409f03133727e38f64469d9bb180f396c84ebf48a42bde3b3769730865ca9df5eb281c
CoreDNS-1.11.1
linux/amd64, go1.21.5, e9c721d80
```

ログにはエラーがなく、CoreDNSがDNSリクエストを正しく処理していることを示しています。

### 次のステップ

CoreDNSポッドのスケジューリングの問題を解決し、アプリケーションが適切に実行されていることを確認しました。追加のDNS解決トラブルシューティングステップについては、次のラボに進みましょう。
