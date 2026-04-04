---
title: "Kubernetes Event-Driven Autoscaler (KEDA)"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "KEDA를 사용하여 Amazon Elastic Kubernetes Service의 워크로드를 자동으로 스케일링합니다"
tmdTranslationSourceHash: '7e242b2451442e01ef5ea9951d4742fa'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment autoscaling/workloads/keda
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- AWS Load Balancer Controller에 필요한 IAM role을 생성합니다
- AWS Load Balancer Controller를 위한 Helm 차트를 배포합니다
- KEDA Operator에 필요한 IAM role을 생성합니다
- UI 워크로드를 위한 Ingress 리소스를 생성합니다

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/workloads/keda/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 [Kubernetes Event-Driven Autoscaler (KEDA)](https://keda.sh/)를 사용하여 배포의 Pod를 스케일링하는 방법을 살펴보겠습니다. Horizontal Pod Autoscaler (HPA)에 대한 이전 실습에서는 HPA 리소스를 사용하여 평균 CPU 사용률을 기반으로 배포의 Pod를 수평으로 스케일링하는 방법을 살펴봤습니다. 그러나 때로는 워크로드가 외부 이벤트나 메트릭을 기반으로 스케일링해야 하는 경우가 있습니다. KEDA는 Amazon SQS의 큐 길이나 CloudWatch의 다른 메트릭과 같은 다양한 이벤트 소스의 이벤트를 기반으로 워크로드를 스케일링할 수 있는 기능을 제공합니다. KEDA는 다양한 메트릭 시스템, 데이터베이스, 메시징 시스템 등에 대한 60개 이상의 [scaler](https://keda.sh/docs/scalers/)를 지원합니다.

KEDA는 Helm 차트를 사용하여 Kubernetes 클러스터에 배포할 수 있는 경량 워크로드입니다. KEDA는 Horizontal Pod Autoscaler와 같은 표준 Kubernetes 컴포넌트와 함께 작동하여 Deployment나 StatefulSet을 스케일링합니다. KEDA를 사용하면 이러한 다양한 이벤트 소스로 스케일링하려는 워크로드를 선택적으로 선택할 수 있습니다.

