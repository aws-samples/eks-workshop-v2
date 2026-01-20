---
title: "追加のプレフィックスを消費する"
sidebar_position: 40
kiteTranslationSourceHash: 22035f7491caa38d7039b931d8b3c95f
---

ワーカーノードに追加のプレフィックスを追加するVPC CNIの動作を実証するために、現在割り当てられているIPアドレスよりも多くのIPアドレスを使用するpauseポッドをデプロイします。多数のこれらのポッドを使用して、デプロイメントやスケーリング操作を通じてクラスターにアプリケーションポッドを追加することをシミュレートします。

::yaml{file="manifests/modules/networking/prefix/deployment-pause.yaml" paths="spec.replicas,spec.template.spec.containers.0.image"}

1. 150個の同一ポッドを作成します
2. イメージを最小限のリソースを消費する軽量なコンテナを提供する`registry.k8s.io/pause`に設定します

pauseポッドのデプロイメントを適用し、準備ができるまで待ちます。`150個のポッド`をスピンアップするには時間がかかる場合があります：

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/networking/prefix
deployment.apps/pause-pods-prefix created
$ kubectl wait --for=condition=available --timeout=60s deployment/pause-pods-prefix -n other
```

pauseポッドが実行状態にあることを確認します：

```bash
$ kubectl get deployment -n other
NAME                READY     UP-TO-DATE   AVAILABLE   AGE
pause-pods-prefix   150/150   150          150         101s
```

ポッドが正常に実行されると、ワーカーノードに追加されたプレフィックスを確認できるはずです。

```bash
$ aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=${EKS_CLUSTER_NAME}" \
  --query 'Reservations[*].Instances[].{InstanceId: InstanceId, Prefixes: NetworkInterfaces[].Ipv4Prefixes[]}'
```

これは、より多くのポッドが特定のノードにスケジュールされると、VPC CNIが動的に`/28`プレフィックスをENI(s)にプロビジョニングして接続する方法を示しています。

