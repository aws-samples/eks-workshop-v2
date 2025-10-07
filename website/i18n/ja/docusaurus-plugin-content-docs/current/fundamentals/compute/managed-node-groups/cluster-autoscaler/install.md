---
title: "インストール"
sidebar_position: 30
kiteTranslationSourceHash: c490f55b166c1d32c68dfd6236322cb1
---

まず、クラスターにcluster-autoscalerをインストールします。ラボの準備として、cluster-autoscalerが適切なAWS APIを呼び出すためのIAMロールがすでに作成されています。

あとはcluster-autoscalerをhelmチャートとしてインストールするだけです：

```bash
$ helm repo add autoscaler https://kubernetes.github.io/autoscaler
$ helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --version "${CLUSTER_AUTOSCALER_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "autoDiscovery.clusterName=${EKS_CLUSTER_NAME}" \
  --set "awsRegion=${AWS_REGION}" \
  --set "image.tag=v${CLUSTER_AUTOSCALER_IMAGE_TAG}" \
  --set "rbac.serviceAccount.name=cluster-autoscaler-sa" \
  --set "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$CLUSTER_AUTOSCALER_ROLE" \
  --wait
NAME: cluster-autoscaler
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

これは`kube-system`ネームスペースにデプロイメントとして実行されます：

```bash
$ kubectl get deployment -n kube-system cluster-autoscaler-aws-cluster-autoscaler
NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE
cluster-autoscaler-aws-cluster-autoscaler   1/1     1            1           51s
```

これで、より多くのコンピュートリソースをプロビジョニングするためにワークロードを変更する準備が整いました。
