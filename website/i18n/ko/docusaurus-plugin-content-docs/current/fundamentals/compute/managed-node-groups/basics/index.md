---
title: MNG 기본 사항
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service의 Managed Node Groups 기본 사항을 학습합니다."
tmdTranslationSourceHash: 3917d0b8357b8a5a37722a603ced394a
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=600 wait=30
$ prepare-environment fundamentals/mng/basics
```

:::

시작하기 실습에서 샘플 애플리케이션을 EKS에 배포하고 실행 중인 Pod를 확인했습니다. 그런데 이러한 Pod는 어디에서 실행되고 있을까요?

사전에 프로비저닝된 기본 managed node group을 살펴볼 수 있습니다:

```bash
$ eksctl get nodegroup --cluster $EKS_CLUSTER_NAME --name $EKS_DEFAULT_MNG_NAME
```

이 출력에서 managed node group의 여러 속성을 확인할 수 있습니다:

- 이 그룹의 노드 수에 대한 최소, 최대 및 희망 개수의 구성. 이 맥락에서 최소값과 최대값은 기본 Autoscaling Group에 대한 경계를 설정하는 것이며, 컴퓨팅 오토스케일링 활성화는 [해당 실습](/docs/autoscaling/compute)에서 다룰 예정입니다.
- 이 node group의 인스턴스 타입은 `m5.large`입니다
- `AL2023_x86_64_STANDARD`는 Amazon EKS 최적화 Amazon Linux 2023 AMI를 사용하고 있음을 나타냅니다. 자세한 내용은 [문서](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html)를 참조하세요.

또한 노드와 가용 영역 내 배치를 살펴볼 수 있습니다.

```bash
$ kubectl get nodes -o wide --label-columns topology.kubernetes.io/zone
```

다음을 확인할 수 있습니다:

- 노드는 여러 가용 영역의 여러 서브넷에 분산되어 있어 고가용성을 제공합니다

이 모듈을 진행하는 동안 MNG의 기본 기능을 시연하기 위해 이 node group을 변경할 것입니다.

