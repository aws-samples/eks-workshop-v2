---
title: "워커 노드"
sidebar_position: 50
description: "Amazon EKS Managed Nodegroup의 워커 노드를 정상 상태로 복구합니다."
sidebar_custom_props: { "module": true }
tmdTranslationSourceHash: dfdf1b903626dbcdbab94a3d5d06ea47
---

다음 워커 노드 시나리오에서는 다양한 AWS EKS 워커 노드 문제를 해결하는 방법을 배웁니다. 각 시나리오는 노드가 클러스터에 조인하지 못하거나 'Not Ready' 상태로 유지되는 원인을 파악한 다음 솔루션으로 문제를 해결하는 과정을 안내합니다. 시작하기 전에 관리형 노드 그룹의 일부로 워커 노드가 배포되는 방법에 대해 자세히 알아보려면 [Fundamentals 모듈](../../fundamentals/compute/managed-node-groups)을 참조하세요.

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/workernodes
```

이 명령으로 적용되는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/workernodes/.workshop/terraform)에서 확인할 수 있습니다.

:::
:::info

실습 환경 준비에는 몇 분 정도 소요되며 다음과 같은 변경 사항이 적용됩니다:

- new_nodegroup_1, new_nodegroup_2, new_nodegroup_3라는 새로운 관리형 노드 그룹을 원하는 관리형 노드 그룹 수를 1로 생성
- 노드 조인 실패 및 준비 문제를 일으키는 관리형 노드 그룹에 문제 발생
- Kubernetes 리소스 배포 (deployment, daemonset, namespace, configmaps, priority-class)

:::

