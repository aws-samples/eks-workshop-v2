---
title: "Karpenter"
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Karpenter를 사용하여 Amazon Elastic Kubernetes Service(EKS)의 컴퓨팅을 자동으로 관리합니다."
---
::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash
$ prepare-environment autoscaling/compute/karpenter
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Karpenter에 필요한 다양한 IAM 역할 및 기타 AWS 리소스를 설치합니다

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/compute/karpenter/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 Kubernetes를 위해 구축된 오픈소스 자동 확장 프로젝트인 [Karpenter](https://github.com/aws/karpenter)에 대해 알아보겠습니다. Karpenter는 스케줄링할 수 없는 파드의 전체 리소스 요청을 관찰하고 스케줄링 지연을 최소화하기 위해 노드를 시작하고 종료하는 결정을 내림으로써, 몇 분이 아닌, 몇 초 안에 애플리케이션의 요구사항에 맞는 적절한 컴퓨팅 리소스를 제공하도록 설계되었습니다.

<img src={require('./assets/karpenter-diagram.webp').default}/>

Karpenter의 목표는 Kubernetes 클러스터에서 워크로드를 실행하는 효율성과 비용을 개선하는 것입니다. Karpenter는 다음과 같이 작동합니다:

- Kubernetes 스케줄러가 스케줄링할 수 없다고 표시한 파드를 감시
- 파드가 요청한 스케줄링 제약 조건(리소스 요청, 노드 셀렉터, 어피니티, 톨러레이션, 토폴로지 스프레드 제약 조건)을 평가
- 파드의 요구사항을 충족하는 노드를 프로비저닝
- 새로운 노드에서 파드를 실행하도록 스케줄링
- 노드가 더 이상 필요하지 않을 때 노드 제거
