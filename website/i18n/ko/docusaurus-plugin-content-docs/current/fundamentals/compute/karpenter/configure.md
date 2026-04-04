---
title: "Karpenter 설치"
sidebar_position: 20
tmdTranslationSourceHash: '8e2cb771899be3e5d53f0a6f56cad924'
---

먼저 클러스터에 Karpenter를 설치하겠습니다. 랩 준비 단계에서 다양한 사전 요구 사항이 생성되었으며, 여기에는 다음이 포함됩니다:

1. Karpenter가 AWS API를 호출하기 위한 IAM role
2. Karpenter가 생성하는 EC2 인스턴스를 위한 IAM role 및 인스턴스 프로파일
3. 노드가 EKS 클러스터에 조인할 수 있도록 노드 IAM role을 위한 EKS 클러스터 액세스 엔트리
4. Karpenter가 Spot 중단, 인스턴스 리밸런스 및 기타 이벤트를 수신하기 위한 SQS 큐

Karpenter의 전체 설치 문서는 [여기](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/)에서 확인할 수 있습니다.

이제 helm 차트로 Karpenter를 설치하기만 하면 됩니다:

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

Karpenter는 `karpenter` 네임스페이스에서 Deployment로 실행됩니다:

```bash
$ kubectl get deployment -n karpenter
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   1/1     1            1           105s
```

이제 Karpenter가 Pod를 위한 인프라를 프로비저닝할 수 있도록 구성을 진행할 수 있습니다.

