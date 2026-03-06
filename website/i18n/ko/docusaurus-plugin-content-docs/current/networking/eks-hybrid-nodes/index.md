---
title: "Amazon EKS Hybrid Nodes"
sidebar_position: 50
sidebar_custom_props: { "module": true }
weight: 10 # used by test framework
description: "Amazon EKS Hybrid Nodes는 클라우드, 온프레미스 및 엣지 환경에서 Kubernetes 관리를 통합하여 확장성, 가용성 및 효율성을 향상시킵니다."
tmdTranslationSourceHash: '1b97045e0b4f9db807839e7f5ada93fe'
---

::required-time{estimatedLabExecutionTimeMinutes="30"}

:::caution 프리뷰
이 모듈은 현재 프리뷰 상태이며, 발생하는 [문제를 보고](https://github.com/aws-samples/eks-workshop-v2/issues)해 주시기 바랍니다.
:::

Amazon EKS Hybrid Nodes는 클라우드, 온프레미스 및 엣지 환경에서 Kubernetes 관리를 통합하여, 어디서나 워크로드를 실행할 수 있는 유연성을 제공하면서 가용성, 확장성 및 효율성을 향상시킵니다. 이는 환경 전반에 걸쳐 Kubernetes 운영 및 도구를 표준화하고, 중앙 집중식 모니터링, 로깅 및 ID 관리를 위해 AWS 서비스와 네이티브로 통합됩니다. EKS Hybrid Nodes는 Kubernetes 컨트롤 플레인의 가용성과 확장성을 AWS로 오프로드하여 온프레미스 및 엣지에서 Kubernetes를 관리하는 데 필요한 시간과 노력을 줄입니다. EKS Hybrid Nodes는 추가 하드웨어 투자 없이 현대화를 가속화하기 위해 기존 인프라에서 실행할 수 있습니다.

Amazon EKS Hybrid Nodes는 사전 약정이나 최소 요금이 없으며, 하이브리드 노드가 Amazon EKS 클러스터에 연결되어 있을 때 vCPU 리소스에 대해 시간당 요금이 청구됩니다. 자세한 가격 정보는 [Amazon EKS 요금](https://aws.amazon.com/eks/pricing/)을 참조하세요.

:::danger
EC2에서 EKS Hybrid Nodes를 실행하는 것은 지원되는 구성이 아닙니다.
이 모듈은 실습 및 데모 목적으로만 EC2에서 EKS Hybrid Nodes를 실행합니다. 사용자는 선택한 리전에서 Amazon EKS를 실행하고, 온프레미스 및 엣지에서 EKS Hybrid Nodes를 실행해야 합니다.
:::

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비합니다:

```bash timeout=600 wait=30
$ prepare-environment networking/eks-hybrid-nodes
```

:::

아래의 아키텍처 다이어그램은 우리가 구축할 내용에 대한 높은 수준의 예시입니다. AWS Transit Gateway를 통해 시뮬레이션된 "원격" 네트워크에 EKS 클러스터를 연결할 것입니다. 프로덕션 환경에서는 원격 네트워크가 일반적으로 AWS Direct Connect 또는 AWS Site-to-Site VPN을 통해 연결됩니다. 이러한 연결은 클러스터 VPC의 Transit Gateway에 연결됩니다. 우리의 "원격" 네트워크에는 실습 목적으로 EKS Hybrid Node로 사용될 단일 EC2 노드가 실행됩니다. 웹 IDE에서 SSH를 통해 이 노드에서 명령을 실행할 것입니다. EC2에서 EKS Hybrid Nodes를 실행하는 것은 **지원되지 않으며**, 데모 목적으로만 여기서 사용하고 있다는 점을 유념하는 것이 중요합니다.

![Architecture Diagram](/docs/networking/eks-hybrid-nodes/lab_environment.png)

