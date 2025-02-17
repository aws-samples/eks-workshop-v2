---
title: "HPA 구성"
sidebar_position: 10
---

현재 우리 클러스터에는 수평적 파드 자동 확장을 가능하게 하는 리소스가 없습니다. 다음 명령어로 이를 확인할 수 있습니다:

```bash expectError=true
$ kubectl get hpa -A
No resources found
```

이번에는 `ui` 서비스를 사용하여 CPU 사용량을 기반으로 스케일링을 수행할 것입니다. 먼저 CPU `request`와 `limit` 값을 지정하기 위해 `ui` 파드 명세를 업데이트하겠습니다.

```kustomization
modules/autoscaling/workloads/hpa/deployment.yaml
Deployment/ui
```

다음으로, HPA가 워크로드를 어떻게 스케일링할지 결정하는 매개변수를 정의하는 `HorizontalPodAutoscaler` 리소스를 생성해야 합니다.

::yaml{file="manifests/modules/autoscaling/workloads/hpa/hpa.yaml" paths="spec.minReplicas,spec.maxReplicas,spec.scaleTargetRef,spec.targetCPUUtilizationPercentage"}

1. 항상 최소 1개의 레플리카를 실행
2. 4개 이상의 레플리카로 스케일링하지 않음
3. HPA에게 `ui` Deployment의 레플리카 수를 변경하도록 지시
4. 목표 CPU 사용률을 80%로 설정

이 구성을 적용해보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/workloads/hpa
```