---
title: "Cluster Autoscaler (CA)"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Cluster Autoscaler를 사용하여 Amazon Elastic Kubernetes Service의 컴퓨팅을 자동으로 관리합니다."
tmdTranslationSourceHash: "52a7905108794621ca7ad7829dd71081"
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment autoscaling/compute/cluster-autoscaler
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- cluster-autoscaler가 사용할 IAM role 생성

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/autoscaling/compute/cluster-autoscaler/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler)를 살펴봅니다. 이는 모든 Pod가 불필요한 노드 없이 실행될 수 있도록 Kubernetes 클러스터의 크기를 자동으로 조정하는 컴포넌트입니다. Cluster Autoscaler는 기본 클러스터 인프라가 탄력적이고 확장 가능하며 워크로드의 변화하는 수요를 충족할 수 있도록 보장하는 훌륭한 도구입니다.

Kubernetes Cluster Autoscaler는 다음 조건 중 하나가 참일 때 Kubernetes 클러스터의 크기를 자동으로 조정합니다:

1. 리소스 부족으로 클러스터에서 실행에 실패하는 Pod가 있는 경우.
2. 클러스터의 노드가 장시간 동안 충분히 활용되지 않고 해당 Pod를 다른 기존 노드에 배치할 수 있는 경우.

AWS용 Cluster Autoscaler는 [Auto Scaling 그룹과의 통합](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws)을 제공합니다.

이 실습에서는 EKS 클러스터에 Cluster Autoscaler를 적용하고 워크로드를 확장할 때 어떻게 동작하는지 확인해 보겠습니다.

