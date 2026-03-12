---
title: "EKS 오픈 소스 관측 가능성"
sidebar_position: 40
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Prometheus와 Grafana와 같은 오픈 소스 관측 가능성 솔루션을 활용합니다."
tmdTranslationSourceHash: 'a6f25e31488b01fd4aa341767fd59b0f'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=600 wait=60 hook=install
$ prepare-environment observability/oss-metrics
```

이 명령은 실습 환경에 다음과 같은 변경사항을 적용합니다:

- OpenTelemetry operator 설치
- ADOT collector가 Amazon Managed Prometheus에 접근할 수 있도록 IAM role 생성

이러한 변경사항을 적용하는 Terraform을 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/oss-metrics/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 [AWS Distro for OpenTelemetry](https://aws-otel.github.io/)를 사용하여 애플리케이션에서 메트릭을 수집하고, Amazon Managed Service for Prometheus에 메트릭을 저장하며, Amazon Managed Grafana를 사용하여 시각화합니다.

AWS Distro for OpenTelemetry는 [OpenTelemetry 프로젝트](https://opentelemetry.io/)의 안전하고, 프로덕션 준비가 완료되었으며, AWS에서 지원하는 배포판입니다. Cloud Native Computing Foundation의 일부인 OpenTelemetry는 애플리케이션 모니터링을 위한 분산 추적과 메트릭을 수집할 수 있는 오픈 소스 API, 라이브러리, 에이전트를 제공합니다. AWS Distro for OpenTelemetry를 사용하면 애플리케이션을 한 번만 계측하여 여러 AWS 및 파트너 모니터링 솔루션에 상관된 메트릭과 추적을 전송할 수 있습니다. 자동 계측 에이전트를 사용하여 코드 변경 없이 추적을 수집할 수 있습니다. AWS Distro for OpenTelemetry는 또한 AWS 리소스 및 관리형 서비스에서 메타데이터를 수집하므로 애플리케이션 성능 데이터를 기반 인프라 데이터와 연관시켜 문제 해결 평균 시간을 단축할 수 있습니다. AWS Distro for OpenTelemetry를 사용하여 Amazon Elastic Compute Cloud(EC2), Amazon Elastic Container Service(ECS), Amazon Elastic Kubernetes Service(EKS) on EC2, AWS Fargate, AWS Lambda 및 온프레미스에서 실행되는 애플리케이션을 계측할 수 있습니다.

Amazon Managed Service for Prometheus는 오픈 소스 Prometheus 프로젝트와 호환되는 메트릭 모니터링 서비스로, 컨테이너 환경을 더 쉽게 안전하게 모니터링할 수 있도록 합니다. Amazon Managed Service for Prometheus는 널리 사용되는 Cloud Native Computing Foundation(CNCF) Prometheus 프로젝트를 기반으로 한 컨테이너 모니터링 솔루션입니다. Amazon Managed Service for Prometheus는 Amazon Elastic Kubernetes Service와 Amazon Elastic Container Service, 그리고 자체 관리형 Kubernetes 클러스터에서 애플리케이션 모니터링을 시작하는 데 필요한 복잡한 작업을 줄여줍니다.

:::info
CDK Observability Accelerator를 사용하는 경우 [ADOT collector](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/existing-eks-observability-accelerators/existing-eks-adotmetrics-collection-observability/), [Nvidia DCGM을 사용한 GPU 모니터링](https://aws-observability.github.io/cdk-aws-observability-accelerator/patterns/single-new-eks-observability-accelerators/single-new-eks-gpu-opensource-observability/) 등 다양한 사용 사례를 다루는 오픈 소스 관측 가능성 패턴 모음을 확인하세요.
:::

