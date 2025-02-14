---
title: "Kubernetes 이벤트 드리븐 오토스케일러 (KEDA)"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "KEDA를 사용하여 Amazon Elastic Kubernetes Service(EKS)에서 워크로드를 자동으로 스케일링"
---
::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash
$ prepare-environment autoscaling/workloads/keda
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- AWS Load Balancer 컨트롤러에 필요한 IAM 역할 생성
- AWS Load Balancer 컨트롤러용 Helm 차트 배포
- KEDA Operator에 필요한 IAM 역할 생성
- UI 워크로드를 위한 Ingress 리소스 생성

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/workloads/keda/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 [Kubernetes 이벤트 드리븐 오토스케일러 (KEDA - Kubernetes Event-Driven Autoscaler)](https://keda.sh/)를 사용하여 디플로이먼트의 파드를 스케일링하는 방법을 살펴보겠습니다. 이전 수평적 파드 오토스케일러(HPA) 실습에서는 HPA 리소스를 사용하여 평균 CPU 사용률을 기반으로 디플로이먼트의 파드를 수평적으로 스케일링하는 방법을 보았습니다. 하지만 때로는 워크로드가 외부 이벤트나 메트릭을 기반으로 스케일링해야 할 필요가 있습니다. KEDA는 Amazon SQS의 대기열 길이나 CloudWatch의 다른 메트릭과 같은 다양한 이벤트 소스의 이벤트를 기반으로 워크로드를 스케일링하는 기능을 제공합니다. KEDA는 다양한 메트릭 시스템, 데이터베이스, 메시징 시스템 등을 위한 60개 이상의 [스케일러](https://keda.sh/docs/scalers/)를 지원합니다.

KEDA는 Helm 차트를 사용하여 Kubernetes 클러스터에 배포할 수 있는 경량 워크로드입니다. KEDA는 수평적 파드 오토스케일러(HPA)와 같은 표준 Kubernetes 컴포넌트와 함께 작동하여 디플로이먼트나 스테이트풀셋을 스케일링합니다. KEDA를 사용하면 이러한 다양한 이벤트 소스로 스케일링하고자 하는 워크로드를 선택적으로 지정할 수 있습니다.

---
