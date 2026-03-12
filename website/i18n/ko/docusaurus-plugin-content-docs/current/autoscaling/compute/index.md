---
title: "컴퓨팅"
sidebar_position: 10
tmdTranslationSourceHash: 'ce6048aabb965ebf98f9ee1a130bf85e'
---

Kubernetes에서 오토스케일링을 보장하고자 하는 첫 번째 측면은 Pod를 실행하는 데 사용되는 EC2 컴퓨팅 인프라입니다. 이는 Pod가 추가되거나 제거됨에 따라 워커 노드로 사용 가능한 EC2 인스턴스의 수를 동적으로 조정합니다.

Kubernetes에서 컴퓨팅 오토스케일링을 구현하는 여러 가지 방법이 있으며, AWS에서는 두 가지 주요 메커니즘을 사용할 수 있습니다:

- Kubernetes Cluster Autoscaler 도구
- Karpenter

이 챕터에서는 Kubernetes Cluster Autoscaler 도구와 Karpenter 메커니즘을 사용하여 AWS의 Kubernetes에서 컴퓨팅 오토스케일링을 달성하는 다양한 방법을 살펴보겠습니다.

