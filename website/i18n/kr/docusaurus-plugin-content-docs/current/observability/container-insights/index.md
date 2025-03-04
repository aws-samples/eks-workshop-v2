---
title: "EKS의 Container Insights"
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Container Insights를 사용하여 Amazon Elastic Kubernetes Service(EKS)의 워크로드에서 메트릭과 로그를 수집, 집계 및 요약합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=60 hook=install
$ prepare-environment observability/container-insights
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- OpenTelemetry 운영자 설치
- CloudWatch 접근을 위한 ADOT 수집기용 IAM 역할 생성

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/container-insights/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)를 활성화하고 사용하여 컨테이너화된 애플리케이션과 마이크로서비스에서 메트릭과 로그를 수집, 집계 및 요약하는 방법을 살펴보겠습니다. Container Insights는 Amazon Elastic Container Service(Amazon ECS), Amazon Elastic Kubernetes Service(EKS) 및 Amazon EC2의 Kubernetes 플랫폼에서 사용할 수 있습니다. Amazon ECS 지원에는 Fargate 지원이 포함됩니다.

메트릭에는 CPU, 메모리, 디스크 및 네트워크와 같은 리소스의 사용률이 포함됩니다. Container Insights는 또한 컨테이너 재시작 실패와 같은 진단 정보를 제공하여 문제를 신속하게 격리하고 해결하는 데 도움을 줍니다. Container Insights가 수집하는 메트릭에 대해 CloudWatch 경보를 설정할 수도 있습니다.

Container Insights가 수집하는 메트릭은 CloudWatch 자동 대시보드에서 확인할 수 있습니다. CloudWatch Logs Insights를 사용하여 컨테이너 성능 및 로그 데이터를 분석하고 문제를 해결할 수 있습니다.

운영 데이터는 성능 로그 이벤트로 수집됩니다. 이는 고카디널리티 데이터를 대규모로 수집하고 저장할 수 있게 해주는 구조화된 JSON 스키마를 사용하는 항목입니다. 이 데이터로부터 CloudWatch는 클러스터, 노드, 파드, 태스크 및 서비스 수준에서 CloudWatch 메트릭으로 집계된 메트릭을 생성합니다.

[AWS Distro for OpenTelemetry 수집기](https://aws-otel.github.io/)를 사용하여 Amazon EKS 클러스터에서 메트릭을 수집하도록 Container Insights를 설정할 것입니다.