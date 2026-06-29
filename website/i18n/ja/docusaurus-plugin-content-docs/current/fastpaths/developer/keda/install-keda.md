---
title: "KEDAのインストール"
sidebar_position: 5
tmdTranslationSourceHash: '5f7ef8141f2a607cd661c7d3cc86726a'
---

まず、Helmを使用してKEDAをインストールしましょう。Auto Modeクラスターのセットアップ時に、CloudWatch内のメトリックデータにアクセスするための権限を持つIAMロールが作成されました。

Amazon EKS Auto Modeでは、IRSAの代わりにEKS Pod Identityを使用します。Pod Identity関連付けを作成しましょう：

```bash wait=10
$ export KEDA_ROLE_ARN=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_AUTO_NAME}-keda
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME} \
  --role-arn ${KEDA_ROLE_ARN} \
  --namespace keda --service-account keda-operator | jq .
```

次にKEDAをインストールします：

```bash timeout=300
$ export KEDA_CHART_VERSION=$(grep -oP 'default\s*=\s*"\K[^"]+' ~/environment/eks-workshop/modules/autoscaling/workloads/keda/.workshop/terraform/vars.tf | tail -1)
$ helm repo add kedacore https://kedacore.github.io/charts
$ helm upgrade --install keda kedacore/keda \
  --version "${KEDA_CHART_VERSION}" \
  --namespace keda \
  --create-namespace \
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

Helmインストール後、KEDAはkedaネームスペース内に複数のDeploymentとして実行されます：

```bash
$ kubectl rollout restart deployment/keda-operator -n keda
$ kubectl rollout status deployment/keda-operator -n keda --timeout=120s
$ kubectl get deployment -n keda
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
keda-admission-webhooks           1/1     1            1           105s
keda-operator                     1/1     1            1           105s
keda-operator-metrics-apiserver   1/1     1            1           105s
```

各KEDAのDeploymentは異なる重要な役割を果たします：

1. Agent (keda-operator) - ワークロードのスケーリングを制御します
2. Metrics (keda-operator-metrics-server) - Kubernetesメトリックサーバーとして機能し、外部メトリックへのアクセスを提供します
3. Admission Webhooks (keda-admission-webhooks) - 設定ミスを防ぐためにリソース設定を検証します（例：同じワークロードをターゲットとする複数のScaledObject）

これで、ワークロードをスケーリングするためのKEDAの設定に進むことができます。

