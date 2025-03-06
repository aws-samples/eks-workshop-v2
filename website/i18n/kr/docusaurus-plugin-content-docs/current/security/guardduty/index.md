---
title: "Amazon EKS를 위한 GuardDuty"
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Amazon GuardDuty를 사용하여 Amazon Elastic Kubernetes Service(EKS) 클러스터에서 잠재적으로 의심스러운 활동을 감지합니다."
---

::required-time{estimatedLabExecutionTimeMinutes="20"}

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment
```

:::

Amazon GuardDuty는 AWS 계정, 워크로드 및 Amazon Simple Storage Service(Amazon S3)에 저장된 데이터를 지속적으로 모니터링하고 보호할 수 있게 해주는 위협 감지 서비스입니다. GuardDuty는 AWS CloudTrail 이벤트, Amazon Virtual Private Cloud(VPC) 흐름 로그, 도메인 이름 시스템(DNS) 로그에서 발견되는 계정 및 네트워크 활동에서 생성된 지속적인 메타데이터 스트림을 분석합니다. GuardDuty는 또한 알려진 악성 IP 주소, 이상 감지, 기계 학습(ML)과 같은 통합된 위협 인텔리전스를 사용하여 더 정확하게 위협을 식별합니다.

Amazon GuardDuty를 사용하면 AWS 계정, 워크로드 및 Amazon S3에 저장된 데이터를 쉽게 지속적으로 모니터링할 수 있습니다. GuardDuty는 리소스와 완전히 독립적으로 작동하므로 워크로드의 성능이나 가용성에 영향을 미칠 위험이 없습니다. 이 서비스는 통합된 위협 인텔리전스, 이상 감지 및 ML과 함께 완전히 관리됩니다. Amazon GuardDuty는 기존 이벤트 관리 및 워크플로우 시스템과 쉽게 통합할 수 있는 상세하고 실행 가능한 경고를 제공합니다. 선불 비용이 없으며 분석된 이벤트에 대해서만 비용을 지불하고, 추가 소프트웨어를 배포하거나 위협 인텔리전스 피드 구독이 필요하지 않습니다.

GuardDuty는 EKS에 대해 두 가지 보호 카테고리를 제공합니다:

1. EKS 감사 로그 모니터링은 Kubernetes 감사 로그 활동을 사용하여 EKS 클러스터에서 잠재적으로 의심스러운 활동을 감지하는 데 도움을 줍니다
1. EKS 런타임 모니터링은 AWS 환경 내의 Amazon Elastic Kubernetes Service(EKS) 노드와 컨테이너에 대한 런타임 위협 감지 범위를 제공합니다

이 섹션에서는 실제 예제를 통해 두 가지 유형의 보호를 모두 살펴보겠습니다.