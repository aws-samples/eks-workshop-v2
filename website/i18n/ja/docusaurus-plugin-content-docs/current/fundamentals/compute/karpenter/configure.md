---
title: "Karpenter のインストール"
sidebar_position: 20
kiteTranslationSourceHash: 8e2cb771899be3e5d53f0a6f56cad924
---

まず最初に、クラスタに Karpenter をインストールします。ラボ準備段階で様々な前提条件が作成されており、それには以下が含まれています：

1. AWS APIを呼び出すための Karpenter 用 IAM ロール
2. Karpenter が作成する EC2 インスタンス用の IAM ロールとインスタンスプロファイル
3. ノードが EKS クラスタに参加できるようにするためのノード IAM ロール用の EKS クラスタアクセスエントリ
4. Karpenter がスポット中断、インスタンスの再バランスなどのイベントを受け取るための SQS キュー

Karpenter の完全なインストールドキュメントは[こちら](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/)で確認できます。

残りの作業は、Karpenter をヘルムチャートとしてインストールすることだけです：

```bash
$ aws ecr-public get-login-password \
  --region us-east-1 | helm registry login \
  --username AWS \
  --password-stdin public.ecr.aws
$ helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "${KARPENTER_VERSION}" \
  --namespace "karpenter" --create-namespace \
  --set "settings.clusterName=${EKS_CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${KARPENTER_SQS_QUEUE}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --set replicas=1 \
  --wait
NAME: karpenter
LAST DEPLOYED: [...]
NAMESPACE: karpenter
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

Karpenter は `karpenter` 名前空間内でデプロイメントとして実行されます：

```bash
$ kubectl get deployment -n karpenter
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   1/1     1            1           105s
```

これで、Karpenter が Pod のためのインフラストラクチャをプロビジョニングできるように設定を進めることができます。

