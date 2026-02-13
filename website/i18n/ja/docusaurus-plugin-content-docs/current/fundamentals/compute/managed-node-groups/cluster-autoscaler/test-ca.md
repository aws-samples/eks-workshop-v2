---
title: "CAによるスケーリング"
sidebar_position: 40
tmdTranslationSourceHash: "88e30a6e724cb75c453a0a55ad3c9524"
---

このセクションでは、アプリケーションコンポーネントのすべてのレプリカ数を4に増やします。これにより、クラスターで利用可能なリソースよりも多くのリソースが消費され、より多くのコンピュートリソースのプロビジョニングがトリガーされます。

```file
manifests/modules/autoscaling/compute/cluster-autoscaler/deployment.yaml
```

これをクラスターに適用しましょう：

```bash hook=ca-pod-scaleout timeout=180
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/cluster-autoscaler
```

一部のPodが`Pending`状態になり、cluster-autoscalerがEC2フリートのスケールアウトをトリガーします。

```bash test=false
$ kubectl get pods -A -o wide --watch
```

cluster-autoscalerのログを表示します：

```bash test=false
$ kubectl -n kube-system logs \
  -f deployment/cluster-autoscaler-aws-cluster-autoscaler
```

cluster-autoscalerによって生成された以下のようなログが表示され、新しいノードを追加するためのスケールアウトイベントが示されます：

```text
...
...
I0411 21:26:52.108599       1 klogx.go:87] Pod ui/ui-68495c748c-dbh22 is unschedulable
I0411 21:26:52.108604       1 klogx.go:87] Pod ui/ui-68495c748c-98gcq is unschedulable
I0411 21:26:52.108608       1 klogx.go:87] Pod ui/ui-68495c748c-8pkdv is unschedulable
I0411 21:26:52.108903       1 orchestrator.go:108] Upcoming 0 nodes
I0411 21:26:52.109318       1 orchestrator.go:181] Best option to resize: eks-default-62c766f6-ec38-5423-ce6a-c4633f142631
I0411 21:26:52.109334       1 orchestrator.go:185] Estimated 1 nodes needed in eks-default-62c766f6-ec38-5423-ce6a-c4633f142631
I0411 21:26:52.109358       1 orchestrator.go:291] Final scale-up plan: [{eks-default-62c766f6-ec38-5423-ce6a-c4633f142631 3->4 (max: 6)}]
I0411 21:26:52.109376       1 executor.go:147] Scale-up: setting group eks-default-62c766f6-ec38-5423-ce6a-c4633f142631 size to 4
I0411 21:26:52.109428       1 auto_scaling_groups.go:267] Setting asg eks-default-62c766f6-ec38-5423-ce6a-c4633f142631 size to 4
...
...
```

[EC2 AWS管理コンソール](https://console.aws.amazon.com/ec2/home?#Instances:sort=instanceId)をチェックして、Auto Scalingグループが需要を満たすためにスケールアップしていることを確認します。これには数分かかる場合があります。コマンドラインからPodのデプロイメント状況を追跡することもできます。ノードがスケールアップされるにつれて、Podがペンディング状態から実行状態に移行するのを確認できるはずです。

または、`kubectl`を使用することもできます：

```bash
$ kubectl get nodes -l workshop-default=yes
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-42-10-159.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-143.us-west-2.compute.internal   Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-11-81.us-west-2.compute.internal    Ready    <none>   3d      vVAR::KUBERNETES_NODE_VERSION
ip-10-42-12-152.us-west-2.compute.internal   Ready    <none>   3m11s   vVAR::KUBERNETES_NODE_VERSION
```
