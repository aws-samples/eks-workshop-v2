---
title: "EKS를 위한 Amazon GuardDuty"
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Amazon GuardDuty를 사용하여 Amazon Elastic Kubernetes Service 클러스터에서 잠재적으로 의심스러운 활동을 탐지합니다."
tmdTranslationSourceHash: "1e21a74b10c998bd34364bedd021d9eb"
---

::required-time{estimatedLabExecutionTimeMinutes="20"}

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment
```

:::

Amazon GuardDuty는 AWS 계정, 워크로드 및 Amazon Simple Storage Service(Amazon S3)에 저장된 데이터를 지속적으로 모니터링하고 보호할 수 있는 위협 탐지 기능을 제공합니다. GuardDuty는 AWS CloudTrail Events, Amazon Virtual Private Cloud(VPC) Flow Logs 및 domain name system(DNS) Logs에서 생성된 지속적인 메타데이터 스트림을 분석합니다. GuardDuty는 또한 알려진 악성 IP 주소, 이상 탐지 및 기계 학습(ML)과 같은 통합된 위협 인텔리전스를 사용하여 위협을 더 정확하게 식별합니다.

Amazon GuardDuty를 사용하면 AWS 계정, 워크로드 및 Amazon S3에 저장된 데이터를 지속적으로 모니터링할 수 있습니다. GuardDuty는 리소스와 완전히 독립적으로 작동하므로 워크로드의 성능이나 가용성에 영향을 미칠 위험이 없습니다. 이 서비스는 통합된 위협 인텔리전스, 이상 탐지 및 ML과 함께 완전 관리형으로 제공됩니다. Amazon GuardDuty는 기존 이벤트 관리 및 워크플로 시스템과 쉽게 통합할 수 있는 상세하고 실행 가능한 알림을 제공합니다. 선불 비용이 없으며 분석된 이벤트에 대해서만 비용을 지불하면 되며, 배포할 추가 소프트웨어나 구독해야 할 위협 인텔리전스 피드가 필요하지 않습니다.

GuardDuty는 EKS에 대해 두 가지 범주의 보호를 제공합니다:

1. EKS Audit Log Monitoring은 Kubernetes 감사 로그 활동을 사용하여 EKS 클러스터에서 잠재적으로 의심스러운 활동을 탐지하는 데 도움을 줍니다
1. EKS Runtime Monitoring은 AWS 환경 내의 Amazon Elastic Kubernetes Service(Amazon EKS) 노드와 컨테이너에 대한 런타임 위협 탐지 범위를 제공합니다

이 섹션에서는 실용적인 예제를 통해 두 가지 유형의 보호 기능을 살펴보겠습니다.

