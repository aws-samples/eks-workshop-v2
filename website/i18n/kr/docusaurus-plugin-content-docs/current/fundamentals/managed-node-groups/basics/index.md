---
title: MNG 기본
sidebar_position: 30
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service(EKS)의 관리형 노드 그룹 기초 학습."
---
::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비하세요:

```bash
$ prepare-environment fundamentals/mng/basics
```

:::

시작하기 실습에서 샘플 애플리케이션을 EKS에 배포하고 실행 중인 Pod를 확인했습니다. 하지만 이러한 Pod들은 어디에서 실행되고 있을까요?

사전 프로비저닝된 기본 관리형 노드 그룹을 검사할 수 있습니다:

```bash
$ eksctl get nodegroup --cluster $EKS_CLUSTER_NAME --name $EKS_DEFAULT_MNG_NAME
```

이 출력에서 관리형 노드 그룹의 여러 속성을 확인할 수 있습니다:

* 이 그룹의 노드 수에 대한 최소, 최대 및 원하는 개수 구성
* 이 노드 그룹의 인스턴스 유형은 `m5.large`입니다
* `AL2_x86_64` EKS AMI 유형을 사용합니다

또한 노드와 가용 영역(AZ)의 배치를 검사할 수 있습니다.

```bash
$ kubectl get nodes -o wide --label-columns topology.kubernetes.io/zone
```

다음과 같은 내용을 볼 수 있습니다:

* 노드들이 여러 가용 영역의 다양한 서브넷에 분산되어 있어 고가용성을 제공합니다

이 모듈을 진행하면서 관리형 노드 그룹(MNG)의 기본 기능을 보여주기 위해 이 노드 그룹을 변경할 것입니다.
