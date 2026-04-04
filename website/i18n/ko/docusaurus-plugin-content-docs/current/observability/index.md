---
title: "관측 가능성"
sidebar_position: 10
weight: 10
tmdTranslationSourceHash: '0fb3e01c3e769a70ad6db087581e176d'
---

관측 가능성은 잘 설계된 EKS 환경의 기본 요소입니다. AWS는 EKS 환경의 모니터링, 로깅 및 알람을 위해 네이티브(CloudWatch) 및 오픈 소스 관리형(Amazon Managed Service for Prometheus, Amazon Managed Grafana 및 AWS Distro for OpenTelemetry) 솔루션을 제공합니다.

이 장에서는 EKS와 통합된 AWS 관측 가능성 솔루션을 사용하여 다음에 대한 가시성을 제공하는 방법을 다룹니다:

- EKS 콘솔 뷰의 Kubernetes 리소스
- Fluentbit를 활용한 컨트롤 플레인 및 Pod 로그
- CloudWatch Container Insights를 사용한 메트릭 모니터링
- AMP 및 ADOT를 사용한 EKS 메트릭 모니터링

모듈 관리자 중 한 명인 Nirmal Mehta(AWS)가 진행하는 관측 가능성 모듈의 비디오 안내를 시청하세요:

<ReactPlayer controls src="https://www.youtube-nocookie.com/embed/ajPe7HVypxg" width={640} height={360} /> <br />

:::info
AWS 관측 가능성 기능에 대해 더 자세히 알아보려면 [One Observability Workshop](https://catalog.workshops.aws/observability/en-US)을 참조하세요
:::

:::info
[AWS Observability Accelerator for CDK](https://aws-observability.github.io/cdk-aws-observability-accelerator/) 및 [AWS Observability Accelerator for Terraform](https://aws-observability.github.io/terraform-aws-observability-accelerator/)에서 AWS 환경에 대한 관측 가능성을 설정하는 데 도움이 되는 의견이 반영된 Infrastructure as Code(IaC) 모듈 세트를 살펴보세요. 이러한 모듈은 Amazon CloudWatch와 같은 AWS 네이티브 서비스 및 Amazon Managed Service for Prometheus, Amazon Managed Grafana, AWS Distro for OpenTelemetry(ADOT)와 같은 AWS 관리형 관측 가능성 서비스와 함께 작동합니다.
:::

![AWS Native Observability](/docs/observability/cloud-native-architecture.webp)

![Open Source Managed Observability ](/docs/observability/oss-architecture.webp)
