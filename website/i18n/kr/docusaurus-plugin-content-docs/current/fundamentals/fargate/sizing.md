---
title: 자원 할당
sidebar_position: 20
---
[Fargate 가격 책정](https://aws.amazon.com/fargate/pricing/)의 주요 차원은 CPU와 메모리를 기반으로 하며, Fargate 인스턴스에 할당되는 리소스의 양은 Pod에서 지정한 리소스 요청에 따라 달라집니다. Fargate에 대해 [문서화된 유효한 CPU 및 메모리 조합 세트](https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html#fargate-cpu-and-memory)가 있으며, 이는 워크로드가 Fargate에 적합한지 평가할 때 고려해야 합니다.

이전 배포에서 우리의 Pod에 프로비저닝된 리소스를 확인하기 위해 주석을 검사할 수 있습니다:

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

이 예시(위)에서 `CapacityProvisioned` 주석은 0.25 vCPU와 0.5 GB의 메모리가 할당되었음을 보여주며, 이는 최소 Fargate 인스턴스 크기입니다. 하지만 우리의 Pod가 더 많은 리소스를 필요로 한다면 어떨까요? 다행히 Fargate는 우리가 시도해볼 수 있는 리소스 요청에 따라 다양한 옵션을 제공합니다.

다음 예시에서는 `checkout` 컴포넌트가 요청하는 리소스의 양을 증가시키고 Fargate 스케줄러가 어떻게 적응하는지 살펴보겠습니다. 우리가 적용할 kustomization은 요청된 리소스를 1 vCPU와 2.5G의 메모리로 증가시킵니다:

```kustomization
modules/fundamentals/fargate/sizing/deployment.yaml
Deployment/checkout
```

kustomization을 적용하고 롤아웃이 완료될 때까지 기다립니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/fargate/sizing
[...]
$ kubectl rollout status -n checkout deployment/checkout --timeout=200s
```

이제 Fargate에 의해 할당된 리소스를 다시 확인해 봅시다. 위에 설명된 변경 사항을 기반으로, 어떤 결과를 예상하시나요?

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

Pod에 의해 요청된 리소스는 위에 설명된 유효한 조합 세트에 나열된 가장 가까운 Fargate 구성으로 반올림되었습니다.
