---
title: "수평적 파드 오토스케일러 (HPA)"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "수평적 파드 오토스케일러(HPA)를 사용하여 Amazon Elastic Kubernetes Service(EKS)에서 워크로드를 자동으로 확장합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment autoscaling/workloads/hpa
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Amazon EKS 클러스터에 Kubernetes Metrics Server 설치

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/workloads/hpa/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 디플로이먼트나 레플리카 셋의 파드를 스케일링하는 수평적 파드 오토스케일러(HPA - Horizontal Pod Autoscaler)에 대해 알아보겠습니다. HPA는 Kubernetes API 리소스와 컨트롤러로 구현됩니다. 리소스는 컨트롤러의 동작을 결정합니다. 컨트롤러 매니저는 각 HorizontalPodAutoscaler 정의에 지정된 메트릭에 대해 리소스 사용률을 조회합니다. 컨트롤러는 CPU 평균 사용률, 메모리 평균 사용률 또는 기타 사용자 정의 메트릭과 같은 메트릭을 관찰하여 사용자가 지정한 목표에 맞게 레플리케이션 컨트롤러나 디플로이먼트의 레플리카 수를 주기적으로 조정합니다. 이러한 메트릭은 리소스 메트릭 API(파드별 리소스 메트릭의 경우) 또는 사용자 정의 메트릭 API(기타 모든 메트릭의 경우)에서 가져옵니다.

Kubernetes Metrics Server는 클러스터의 리소스 사용 데이터를 확장 가능하고 효율적으로 집계하는 도구입니다. 수평적 파드 오토스케일러(HPA)에 필요한 컨테이너 메트릭을 제공합니다. 메트릭 서버는 Amazon EKS 클러스터에 기본적으로 배포되어 있지 않습니다.

<img src={require('./assets/hpa.webp').default}/>