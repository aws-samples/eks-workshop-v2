---
title: 리소스 할당
sidebar_position: 20
tmdTranslationSourceHash: 5fc8ef93035d670c6eb30eb4380101ec
---

[Fargate 가격 책정](https://aws.amazon.com/fargate/pricing/)의 주요 차원은 CPU와 메모리를 기반으로 하며, Fargate 인스턴스에 할당되는 리소스의 양은 Pod가 지정한 리소스 요청에 따라 달라집니다. 워크로드가 Fargate에 적합한지 평가할 때 고려해야 할 Fargate의 [문서화된 유효한 CPU 및 메모리 조합 세트](https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html#fargate-cpu-and-memory)가 있습니다.

Pod의 주석을 검사하여 이전 배포에서 Pod에 프로비저닝된 리소스를 확인할 수 있습니다:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].metadata.annotations'
{
  "CapacityProvisioned": "0.25vCPU 0.5GB",
  "Logging": "LoggingDisabled: LOGGING_CONFIGMAP_NOT_FOUND",
  "kubernetes.io/psp": "eks.privileged",
  "prometheus.io/path": "/metrics",
  "prometheus.io/port": "8080",
  "prometheus.io/scrape": "true"
}
```

위의 예에서 `CapacityProvisioned` 주석이 0.25 vCPU와 0.5GB의 메모리가 할당되었음을 보여주는데, 이는 최소 Fargate 인스턴스 크기입니다. 하지만 Pod에 더 많은 리소스가 필요하다면 어떻게 될까요? 다행히 Fargate는 요청하는 리소스에 따라 시도해볼 수 있는 다양한 옵션을 제공합니다.

다음 예제에서는 `checkout` 컴포넌트가 요청하는 리소스의 양을 늘리고 Fargate 스케줄러가 어떻게 적응하는지 살펴보겠습니다. 적용할 kustomization은 요청되는 리소스를 1 vCPU와 2.5G의 메모리로 증가시킵니다:

```kustomization
modules/fundamentals/fargate/sizing/deployment.yaml
Deployment/checkout
```

kustomization을 적용하고 롤아웃이 완료될 때까지 기다립니다:

```bash timeout=220
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/sizing
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

이제 Fargate가 할당한 리소스를 다시 확인해 보겠습니다. 위에 설명된 변경 사항을 기반으로 무엇을 볼 것으로 예상하시나요?

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service -o json | jq -r '.items[0].metadata.annotations'
{
  "CapacityProvisioned": "1vCPU 3GB",
  "Logging": "LoggingDisabled: LOGGING_CONFIGMAP_NOT_FOUND",
  "kubernetes.io/psp": "eks.privileged",
  "prometheus.io/path": "/metrics",
  "prometheus.io/port": "8080",
  "prometheus.io/scrape": "true"
}
```

Pod가 요청한 리소스는 위에 설명된 유효한 조합 세트에서 가장 가까운 Fargate 구성으로 반올림되었습니다.

