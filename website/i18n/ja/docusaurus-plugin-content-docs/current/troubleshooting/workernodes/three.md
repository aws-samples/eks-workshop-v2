---
title: "ノードがNot-Ready状態"
sidebar_position: 73
chapter: true
tmdTranslationSourceHash: 09464da5ad3fd035147d80e84aa037dc
---

::required-time

### 背景

Corporation XYZのDevOpsチームは新しいノードグループをデプロイし、アプリケーションチームはretail-app以外の新しいアプリケーションをデプロイしました。これにはデプロイメント（prod-app）とそれをサポートするDaemonSet（prod-ds）が含まれています。

これらのアプリケーションをデプロイした後、監視チームはノードが**_NotReady_**状態に移行していることを報告しています。根本的な原因はすぐには明らかではなく、DevOpsのオンコールエンジニアとして、ノードが応答しなくなっている理由を調査し、正常な動作を回復するための解決策を実装する必要があります。

### ステップ1: ノードの状態を確認する

まず、ノードの状態を確認して、現在の状態を確認しましょう：

```bash timeout=40 hook=fix-3-1 hookTimeout=60 wait=30
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3
NAME                                          STATUS     ROLES    AGE     VERSION
ip-10-42-180-244.us-west-2.compute.internal   NotReady   <none>   15m     v1.27.1-eks-2f008fe
```

### ステップ2: ノード名をエクスポートする

```bash
$ NODE_NAME=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 --no-headers | awk '{print $1}' | head -1)
```

### ステップ3: システムPodの状態をチェックする

影響を受けているノード上のkube-system podsの状態を調べて、システムレベルの問題を特定しましょう：

```bash
$ kubectl get pods -n kube-system -o wide --field-selector spec.nodeName=$NODE_NAME
```

このコマンドは、影響を受けたノード上で実行されているすべてのkube-system podsを表示し、それらによって引き起こされる可能性のあるノードの問題を特定するのに役立ちます。すべてのpodがrunning状態であることに注意してください。

### ステップ4: ノードの状態を調べる

*NotReady*状態の原因を理解するために、ノードのdescribe出力を調べてみましょう。

```bash
$ kubectl describe node $NODE_NAME | sed -n '/^Taints:/,/^[A-Z]/p;/^Conditions:/,/^[A-Z]/p;/^Events:/,$p'


Taints:             node.kubernetes.io/unreachable:NoExecute
                    node.kubernetes.io/unreachable:NoSchedule
Unschedulable:      false
Conditions:
  Type             Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
  ----             ------    -----------------                 ------------------                ------              -------
  MemoryPressure   Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  DiskPressure     Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  PIDPressure      Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  Ready            Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
Addresses:
Events:
  Type     Reason                   Age                    From                     Message
  ----     ------                   ----                   ----                     -------
  Normal   Starting                 3m18s                  kube-proxy
  Normal   Starting                 3m31s                  kubelet                  Starting kubelet.
  Warning  InvalidDiskCapacity      3m31s                  kubelet                  invalid capacity 0 on image filesystem
  Normal   NodeHasSufficientMemory  3m31s (x2 over 3m31s)  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeHasSufficientMemory
  Normal   NodeHasNoDiskPressure    3m31s (x2 over 3m31s)  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeHasNoDiskPressure
  Normal   NodeHasSufficientPID     3m31s (x2 over 3m31s)  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeHasSufficientPID
  Normal   NodeAllocatableEnforced  3m31s                  kubelet                  Updated Node Allocatable limit across pods
  Normal   RegisteredNode           3m27s                  node-controller          Node ip-10-42-180-244.us-west-2.compute.internal event: Registered Node ip-10-42-180-244.us-west-2.compute.internal in Controller
  Normal   Synced                   3m27s                  cloud-node-controller    Node synced successfully
  Normal   ControllerVersionNotice  3m12s                  vpc-resource-controller  The node is managed by VPC resource controller version v1.6.3
  Normal   NodeReady                3m10s                  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeReady
  Normal   NodeTrunkInitiated       3m8s                   vpc-resource-controller  The node has trunk interface initialized successfully
  Warning  SystemOOM                94s                    kubelet                  System OOM encountered, victim process: python, pid: 4763
  Normal   NodeNotReady             52s                    node-controller          Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeNotReady
```

ここでは、ノードのkubeletが*Unknown*状態にあり、到達できないことがわかります。このステータスについては、[Kubernetesドキュメント](https://kubernetes.io/docs/reference/node/node-status/#condition)で詳細を確認できます。

:::note ノードステータス情報
ノードには次のtaintsがあります：

- **node.kubernetes.io/unreachable:NoExecute**: このtaintを許容しないポッドは退避されることを示します
- **node.kubernetes.io/unreachable:NoSchedule**: 新しいポッドがスケジュールされるのを防ぎます

ノードの状態は、kubeletがステータスの更新を停止したことを示しています。これは通常、深刻なリソース制約やシステムの不安定さを示しています。
:::

### ステップ5: CloudWatchメトリクスの調査

Metrics Serverがデータを提供していないため、CloudWatchを使用してEC2インスタンスのメトリクスを確認しましょう：

:::info
便宜上、new_nodegroup_3のワーカーノードのインスタンスIDが環境変数*$INSTANCE_ID*として保存されています。
:::

```bash
$ aws cloudwatch get-metric-data --region $AWS_REGION --start-time $(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ") --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") --metric-data-queries '[{"Id":"cpu","MetricStat":{"Metric":{"Namespace":"AWS/EC2","MetricName":"CPUUtilization","Dimensions":[{"Name":"InstanceId","Value":"'$INSTANCE_ID'"}]},"Period":60,"Stat":"Average"}}]'

{
    "MetricDataResults": [
        {
            "Id": "cpu",
            "Label": "CPUUtilization",
            "Timestamps": [
                "2025-0X-XXT16:25:00+00:00",
                "2025-0X-XXT16:20:00+00:00",
                "2025-0X-XXT16:15:00+00:00",
                "2025-0X-XXT16:10:00+00:00"
            ],
            "Values": [
                99.87333333333333,
                99.89633636636336,
                99.86166666666668,
                62.67880324995537
            ],
            "StatusCode": "Complete"
        }
    ],
    "Messages": []
}
```

:::info
CloudWatchメトリクスは以下を示しています：

- CPU使用率が常に99％以上
- 時間の経過とともにリソース使用量が著しく増加
- リソース枯渇の明確な兆候

:::

### ステップ6: 影響を緩和する

デプロイメントの詳細をチェックして、ノードを安定させるために即時の変更を実装しましょう：

#### 6.1. デプロイメントのリソース構成を確認する

```bash
$ kubectl get pods -n prod -o custom-columns="NAME:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEM_REQUEST:.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEM_LIMIT:.spec.containers[*].resources.limits.memory"
NAME                        CPU_REQUEST   MEM_REQUEST   CPU_LIMIT   MEM_LIMIT
prod-app-74b97f9d85-k6c84   100m          64Mi          <none>      <none>
prod-app-74b97f9d85-mpcrv   100m          64Mi          <none>      <none>
prod-app-74b97f9d85-wdqlr   100m          64Mi          <none>      <none>
...
...
prod-ds-558sx               100m          128Mi         <none>      <none>
```

:::info
デプロイメントもDaemonSetもリソース制限が設定されていないことに注意してください。これにより、無制限のリソース消費が許可されています。
:::

#### 6.2. デプロイメントをスケールダウンしてリソースのオーバーロードを停止する

```bash bash timeout=40 wait=25
$ kubectl scale deployment/prod-app -n prod --replicas=0 && kubectl delete pod -n prod -l app=prod-app --force --grace-period=0 && kubectl wait --for=delete pod -n prod -l app=prod-app
```

#### 6.3. ノードグループのノードをリサイクルする

```bash timeout=120 wait=95
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --scaling-config desiredSize=0 && \
aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 && \
aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --labels "addOrUpdateLabels={status=new-node}" && \
aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 && \
aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --scaling-config desiredSize=1 && \
aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 && \
for i in {1..12}; do NODE_NAME_2=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3,status=new-node --no-headers -o custom-columns=":metadata.name" 2>/dev/null) && [ -n "$NODE_NAME_2" ] && break || sleep 5; done && \
[ -n "$NODE_NAME_2" ]
```

:::info
これには1分強かかる場合があります。スクリプトは新しいノード名をNODE_NAME_2として保存します。
:::

#### 6.4. ノードのステータスを確認する

```bash test=false
$ kubectl get nodes --selector=kubernetes.io/hostname=$NODE_NAME_2
NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-42-180-24.us-west-2.compute.internal    Ready    <none>   0h43m   v1.30.8-eks-aeac579
```

### ステップ7: 長期的な解決策の実装

開発チームはアプリケーションのメモリリークを特定して修正しました。修正を実装し、適切なリソース管理を確立しましょう：

#### 7.1. 更新されたアプリケーション構成を適用する

```bash timeout=10 wait=5
$ kubectl apply -f /home/ec2-user/environment/eks-workshop/modules/troubleshooting/workernodes/yaml/configmaps-new.yaml
```

#### 7.2. デプロイメントのリソース制限を設定する（cpu: 500m、memory: 512Mi）

```bash timeout=10 wait=5
$ kubectl patch deployment prod-app -n prod --patch '{"spec":{"template":{"spec":{"containers":[{"name":"prod-app","resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}}]}}}}'
```

#### 7.3. DaemonSetのリソース制限を設定する（cpu: 500m、memory: 512Mi）

```bash timeout=10 wait=5
$ kubectl patch daemonset prod-ds -n prod --patch '{"spec":{"template":{"spec":{"containers":[{"name":"prod-ds","resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}}]}}}}'
```

#### 7.4. ローリングアップデートを実行し、目的の状態にスケールバックする

```bash timeout=20 wait=10
$ kubectl rollout restart deployment/prod-app -n prod && kubectl rollout restart daemonset/prod-ds -n prod && kubectl scale deployment prod-app -n prod --replicas=6
```

### ステップ8: 検証

修正によって問題が解決されたことを確認しましょう：

#### 8.1 Pod作成を確認する

```bash test=false
$ kubectl get pods -n prod
NAME                        READY   STATUS    RESTARTS   AGE
prod-app-666f8f7bd5-658d6   1/1     Running   0          1m
prod-app-666f8f7bd5-6jrj4   1/1     Running   0          1m
prod-app-666f8f7bd5-9rf6m   1/1     Running   0          1m
prod-app-666f8f7bd5-pm545   1/1     Running   0          1m
prod-app-666f8f7bd5-ttkgs   1/1     Running   0          1m
prod-app-666f8f7bd5-zm8lx   1/1     Running   0          1m
prod-ds-ll4lv               1/1     Running   0          1m
```

#### 8.2. Pod制限を確認する

```bash
$ kubectl get pods -n prod -o custom-columns="NAME:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEM_REQUEST:.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEM_LIMIT:.spec.containers[*].resources.limits.memory"
NAME                        CPU_REQUEST   MEM_REQUEST   CPU_LIMIT   MEM_LIMIT
prod-app-6d67889dc8-4hc7m   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-6s8wr   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-fd6kq   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-gzcbn   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-qvtvj   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-rf478   250m          256Mi         500m        512Mi
prod-ds-srdqx               250m          256Mi         500m        512Mi
```

#### 8.3 ノードCPUリソースを確認する

```bash wait=300 test=false
$ INSTANCE_ID=$(kubectl get node ${NODE_NAME_2} -o jsonpath='{.spec.providerID}' | cut -d '/' -f5) && aws cloudwatch get-metric-data --region $AWS_REGION --start-time $(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ") --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") --metric-data-queries '[{"Id":"cpu","MetricStat":{"Metric":{"Namespace":"AWS/EC2","MetricName":"CPUUtilization","Dimensions":[{"Name":"InstanceId","Value":"'$INSTANCE_ID'"}]},"Period":60,"Stat":"Average"}}]'
{
    "MetricDataResults": [
        {
            "Id": "cpu",
            "Label": "CPUUtilization",
            "Timestamps": [
                "2025-0X-XXT18:30:00+00:00",
                "2025-0X-XXT18:25:00+00:00"
            ],
            "Values": [
                88.05,
                58.63008430846801
            ],
            "StatusCode": "Complete"
        }
    ],
    "Messages": []
}
```

:::info
CPUが過剰に使用されていないことを確認してください。
:::

#### 8.4. ノードのステータスを確認する

```bash
$ kubectl get node --selector=kubernetes.io/hostname=$NODE_NAME_2
NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-42-180-24.us-west-2.compute.internal    Ready    <none>   1h35m   v1.30.8-eks-aeac579
```

### 重要なポイント

#### 1. リソース管理

- 常に適切なリソース要求と制限を設定する
- 累積ワークロードの影響を監視する
- 適切なリソースクォータを実装する

#### 2. モニタリング

- 複数の監視ツールを使用する
- 事前警告アラートを設定する
- コンテナとノードレベルの両方のメトリクスを監視する

#### 3. ベストプラクティス

- 水平Pod自動スケーリングを実装する
- 自動スケーリングを使用する：[Cluster-autoscaler](https://docs.aws.amazon.com/eks/latest/best-practices/cas.html)、[Karpenter](https://docs.aws.amazon.com/eks/latest/best-practices/karpenter.html)、[EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
- 定期的な容量計画
- アプリケーションでの適切なエラー処理の実装

### 追加リソース

- [Kubernetesリソース管理](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [リソース不足の処理](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/)
- [EKSベストプラクティス](https://aws.github.io/aws-eks-best-practices/)
- [Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-metrics-EKS.html)
- [Knowledge Centerガイド](https://repost.aws/knowledge-center/eks-node-status-ready)
