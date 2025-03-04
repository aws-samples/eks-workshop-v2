---
title: "클러스터 오토스케일러 (CA)"
sidebar_position: 20
sidebar_custom_props: { "module": true }
description: "클러스터 오토스케일러를 사용하여 Amazon Elastic Kubernetes Service(EKS)의 컴퓨팅 자원을 자동으로 관리합니다."
---
::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash
$ prepare-environment autoscaling/compute/cluster-autoscaler
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- `cluster-autoscaler`가 사용할 IAM 역할 생성

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/compute/cluster-autoscaler/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 [Kubernetes 클러스터 오토스케일러](https://github.com/kubernetes/autoscaler)를 살펴볼 것입니다. 이는 모든 파드가 불필요한 노드 없이 실행될 수 있도록 Kubernetes 클러스터의 크기를 자동으로 조정하는 컴포넌트입니다. 클러스터 오토스케일러는 기반 클러스터 인프라가 탄력적이고 확장 가능하며 워크로드의 변화하는 요구사항을 충족시킬 수 있도록 보장하는 훌륭한 도구입니다.

Kubernetes 클러스터 오토스케일러는 다음 조건 중 하나가 참일 때 Kubernetes 클러스터의 크기를 자동으로 조정합니다:

1. 리소스 부족으로 인해 클러스터에서 실행할 수 없는 파드가 있는 경우
2. 장시간 동안 활용도가 낮은 노드가 있고, 해당 노드의 파드들을 다른 기존 노드로 옮길 수 있는 경우

AWS용 클러스터 오토스케일러는 [Auto Scaling Group과의 통합](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws)을 제공합니다.

이 실습에서는 EKS 클러스터에 클러스터 오토스케일러를 적용하고 워크로드를 확장할 때 어떻게 동작하는지 살펴볼 것입니다.
