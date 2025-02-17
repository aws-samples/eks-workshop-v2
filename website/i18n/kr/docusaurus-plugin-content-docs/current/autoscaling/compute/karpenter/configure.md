---
title: "Karpenter 설치"
sidebar_position: 20
---

가장 먼저 할 일은 클러스터에 Karpenter를 설치하는 것입니다. 실습 준비 단계에서 다음과 같은 여러 사전 요구사항들이 생성되었습니다:

1. AWS API를 호출하기 위한 Karpenter용 IAM 역할
2. Karpenter가 생성하는 EC2 인스턴스를 위한 IAM 역할 및 인스턴스 프로파일
3. 노드가 EKS 클러스터에 조인할 수 있도록 하는 노드 IAM 역할을 위한 EKS 클러스터 접근 항목
4. Karpenter가 스팟 인터럽션, 인스턴스 리밸런싱 및 기타 이벤트를 수신하기 위한 SQS 대기열

Karpenter의 전체 설치 문서는 [여기](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/)에서 확인할 수 있습니다.

이제 남은 것은 helm 차트로 Karpenter를 설치하는 것뿐입니다:

```bash
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

Karpenter는 `karpenter` 네임스페이스에서 디플로이먼트로 실행됩니다:

```bash
$ kubectl get deployment -n karpenter
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   1/1     1            1           105s
```

이제 Karpenter가 파드를 위한 인프라를 프로비저닝하도록 구성하는 단계로 넘어갈 수 있습니다.