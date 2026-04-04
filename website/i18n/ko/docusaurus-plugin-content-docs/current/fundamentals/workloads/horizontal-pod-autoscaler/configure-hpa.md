---
title: "HPA 구성"
sidebar_position: 10
tmdTranslationSourceHash: '7b21bff45ccd701d11889828ddeb5995'
---

현재 클러스터에는 Horizontal Pod Autoscaling을 활성화하는 리소스가 없습니다. 다음 명령으로 확인할 수 있습니다:

```bash expectError=true
$ kubectl get hpa -A
No resources found
```

이 경우 `ui` 서비스를 사용하여 CPU 사용량을 기반으로 스케일링하겠습니다. 먼저 `ui` Pod 사양을 업데이트하여 CPU `request`와 `limit` 값을 지정하겠습니다.

```kustomization
modules/autoscaling/workloads/hpa/deployment.yaml
Deployment/ui
```

다음으로, HPA가 워크로드를 스케일링하는 방법을 결정하는 데 사용할 파라미터를 정의하는 `HorizontalPodAutoscaler` 리소스를 생성해야 합니다.

::yaml{file="manifests/modules/autoscaling/workloads/hpa/hpa.yaml" paths="spec.minReplicas,spec.maxReplicas,spec.scaleTargetRef,spec.targetCPUUtilizationPercentage"}

1. 항상 최소 1개의 replica를 실행합니다
2. 4개 이상의 replica로 스케일링하지 않습니다
3. HPA에게 `ui` Deployment의 replica 수를 변경하도록 지시합니다
4. 목표 CPU 사용률을 80%로 설정합니다

이 구성을 적용해 보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/workloads/hpa
```

