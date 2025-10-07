---
title: "KEDAのインストール"
sidebar_position: 5
kiteTranslationSourceHash: 5370e0b7bace72b2768788d3047bda59
---

まず、Helmを使用してKEDAをインストールしましょう。ラボの準備段階で作成された前提条件が1つあります。CloudWatch内のメトリックデータにアクセスするための権限を持つIAMロールが作成されました。

```bash
$ helm repo add kedacore https://kedacore.github.io/charts
$ helm upgrade --install keda kedacore/keda \
  --version "${KEDA_CHART_VERSION}" \
  --namespace keda \
  --create-namespace \
  --set "podIdentity.aws.irsa.enabled=true" \
  --set "podIdentity.aws.irsa.roleArn=${KEDA_ROLE_ARN}" \
  --wait
Release "keda" does not exist. Installing it now.
NAME: keda
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
[...]
```

Helmインストール後、KEDAはkedaネームスペースでいくつかのデプロイメントとして実行されます：

```bash
$ kubectl get deployment -n keda
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
keda-admission-webhooks           1/1     1            1           105s
keda-operator                     1/1     1            1           105s
keda-operator-metrics-apiserver   1/1     1            1           105s
```

各KEDAデプロイメントは異なる重要な役割を果たします：

1. エージェント（keda-operator） - ワークロードのスケーリングを制御します
2. メトリクス（keda-operator-metrics-server） - Kubernetesメトリクスサーバーとして機能し、外部メトリクスへのアクセスを提供します
3. アドミッションWebhooks（keda-admission-webhooks） - リソース設定を検証して設定ミスを防止します（例：同じワークロードをターゲットにする複数のScaledObjects）

これでワークロードをスケーリングするためのKEDAの設定に進むことができます。

