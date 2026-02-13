---
title: "スケーリングのトリガー"
date: 2022-07-21T00:00:00-03:00
sidebar_position: 3
tmdTranslationSourceHash: be868c3a133b355f49a3c6cc792b5a76
---

前のセクションでインストールした Cluster Proportional Autoscaler (CPA) をテストしてみましょう。現在、3ノードのクラスタを実行しています：

```bash
$ kubectl get nodes
NAME                                            STATUS   ROLES    AGE   VERSION
ip-10-42-109-155.us-east-2.compute.internal     Ready    <none>   76m   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-142-113.us-east-2.compute.internal     Ready    <none>   76m   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-80-39.us-east-2.compute.internal       Ready    <none>   76m   vVAR::KUBERNETES_NODE_VERSION
```

設定で定義したスケーリングパラメータに基づいて、CPA が CoreDNS を 2 レプリカにスケールしたことが確認できます：

```bash
$ kubectl get po -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-5db97b446d-5zwws   1/1     Running   0          66s
coredns-5db97b446d-n5mp4   1/1     Running   0          89m
```

EKS クラスタのサイズを 5 ノードに増やすと、Cluster Proportional Autoscaler は自動的に CoreDNS レプリカの数を増やして追加のノードに対応します：

```bash hook=cpa-pod-scaleout timeout=300
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME --scaling-config desiredSize=$(($EKS_DEFAULT_MNG_DESIRED+2))
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_DEFAULT_MNG_NAME
$ kubectl wait --for=condition=Ready nodes --all --timeout=120s
```

Kubernetes は現在、すべての 5 ノードが `Ready` 状態であることを示しています：

```bash
$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-42-10-248.us-west-2.compute.internal    Ready    <none>   61s   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-10-29.us-west-2.compute.internal     Ready    <none>   124m  vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-109.us-west-2.compute.internal    Ready    <none>   6m39s vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-152.us-west-2.compute.internal    Ready    <none>   61s   vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-139.us-west-2.compute.internal    Ready    <none>   6m20s vVAR::KUBERNETES_NODE_VERSION
```

そして、CoreDNS Pod の数が 3 に増加したことがわかります。これは、ノード 2 つごとに 1 つのレプリカという設定に基づいています：

```bash
$ kubectl get po -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-657694c6f4-klj6w   1/1     Running   0          14h
coredns-657694c6f4-tdzsd   1/1     Running   0          54s
coredns-657694c6f4-wmnnc   1/1     Running   0          14h
```

CPA のログを調べると、クラスタ内のノード数の変化にどのように対応したかを確認できます：

```bash
$ kubectl logs deployment/cluster-proportional-autoscaler -n kube-system
{"includeUnschedulableNodes":true,"max":6,"min":2,"nodesPerReplica":2,"preventSinglePointFailure":true}
I0801 15:02:45.330307       1 k8sclient.go:272] Cluster status: SchedulableNodes[1], SchedulableCores[2]
I0801 15:02:45.330328       1 k8sclient.go:273] Replicas are not as expected : updating replicas from 2 to 3
```

ログから、CPA がクラスタサイズの変化を検出し、それに応じて CoreDNS レプリカの数を調整したことが確認できます。
