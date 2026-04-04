---
title: "Kubecost를 통한 비용 가시성"
sidebar_position: 60
sidebar_custom_props: { "module": true }
description: "Kubecost를 사용하여 Amazon Elastic Kubernetes Service를 사용하는 팀의 비용 가시성과 인사이트를 확보하세요."
tmdTranslationSourceHash: 'e20f9e5f9b5d9256c23c154ba9c78128'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment observability/kubecost
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- Amazon EKS 클러스터에 AWS Load Balancer controller 설치
- EBS CSI driver를 위한 EKS 관리형 애드온 설치

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/kubecost/.workshop/terraform)에서 확인할 수 있습니다.

:::

Kubecost는 Kubernetes를 사용하는 팀에게 실시간 비용 가시성과 인사이트를 제공하여 클라우드 비용을 지속적으로 절감할 수 있도록 돕습니다.

AWS Cost and Usage Reports를 사용하여 Kubernetes 컨트롤 플레인과 EC2 비용을 추적할 수 있지만, 더 깊은 인사이트가 필요할 수 있습니다. Kubecost를 사용하면 네임스페이스, 클러스터, Pod 또는 조직적 개념(예: 팀 또는 애플리케이션별)으로 Kubernetes 리소스를 정확하게 추적할 수 있습니다. 이는 멀티 테넌트 클러스터 환경을 운영할 때 클러스터의 테넌트별로 비용을 분류해야 하는 경우에도 유용합니다. 예를 들어, Kubecost를 사용하면 특정 Pod 그룹이 사용하는 리소스를 결정할 수 있습니다. 일반적으로 고객들은 특정 기간의 컴퓨팅 리소스 사용량을 수동으로 집계하여 비용을 계산해야 했습니다. 컨테이너는 수명이 짧고 다양한 수준에서 스케일링되므로 리소스 사용량이 시간에 따라 변동하여 이 계산이 더욱 복잡해집니다.

이것이 바로 Kubecost가 해결하고자 하는 과제입니다. 2019년에 설립된 Kubecost는 고객에게 Kubernetes 환경에서 지출 및 리소스 효율성에 대한 가시성을 제공하기 위해 출시되었으며, 현재 수천 개의 팀이 이 과제를 해결하는 데 도움을 주고 있습니다. Kubecost는 최근 CNCF(Cloud Native Computing Foundation) Sandbox 프로젝트로 승인된 OpenCost를 기반으로 구축되었으며, AWS에서 적극적으로 지원하고 있습니다.

이 챕터에서는 Kubecost를 사용하여 네임스페이스 레벨, 배포 레벨 및 Pod 레벨에서 다양한 컴포넌트의 비용 할당을 측정하는 방법을 살펴봅니다. 또한 배포가 과다 프로비저닝되었는지 또는 과소 프로비저닝되었는지 확인하기 위한 리소스 효율성, 시스템의 상태 등을 확인합니다.

:::tip
이 모듈을 완료한 후 Kubecost와 [Amazon Managed Service for Prometheus](https://docs.aws.amazon.com/prometheus/latest/userguide/what-is-Amazon-Managed-Service-Prometheus.html)를 사용하여 단일 EKS 클러스터를 넘어 비용 가시성을 확장하는 방법을 [Multi-Cluster Cost Monitoring](https://aws.amazon.com/blogs/containers/multi-cluster-cost-monitoring-using-kubecost-with-amazon-eks-and-amazon-managed-service-for-prometheus/)에서 확인하세요. [Amazon Cognito를 사용하여 Kubecost 대시보드에 대한 액세스를 보호하는 방법](https://aws.amazon.com/blogs/containers/securing-kubecost-access-with-amazon-cognito/)을 알아보세요.

:::

:::info
CDK Observability Accelerator를 사용하는 경우 [Kubecost Addon](https://aws-quickstart.github.io/cdk-eks-blueprints/addons/kubecost/)을 확인하세요. 이 애드온은 EKS 클러스터에 대한 Kubecost 및 AMP 설정 프로세스를 크게 단순화합니다.
:::

