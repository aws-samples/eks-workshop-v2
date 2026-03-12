---
title: "설치"
sidebar_position: 30
tmdTranslationSourceHash: 'c490f55b166c1d32c68dfd6236322cb1'
---

먼저 클러스터에 cluster-autoscaler를 설치하겠습니다. 실습 준비 과정에서 cluster-autoscaler가 적절한 AWS API를 호출할 수 있도록 IAM 역할이 이미 생성되었습니다.

이제 남은 작업은 cluster-autoscaler를 helm 차트로 설치하는 것입니다:

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

cluster-autoscaler는 `kube-system` 네임스페이스에서 Deployment로 실행됩니다:

```bash
$ kubectl get deployment -n kube-system cluster-autoscaler-aws-cluster-autoscaler
NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE
cluster-autoscaler-aws-cluster-autoscaler   1/1     1            1           51s
```

이제 더 많은 컴퓨팅 리소스가 프로비저닝되도록 워크로드를 수정할 수 있습니다.

