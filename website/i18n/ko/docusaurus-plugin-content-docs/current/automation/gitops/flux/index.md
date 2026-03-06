---
title: "Flux"
sidebar_position: 2
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Flux를 사용하여 지속적이고 점진적인 배포를 구현합니다."
tmdTranslationSourceHash: "1d05d9460507fed9d11255be1c07ee97"
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment automation/gitops/flux
```

이 명령은 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Amazon EKS 클러스터에 AWS Load Balancer controller 설치
- EBS CSI driver를 위한 EKS 관리형 애드온 설치

이러한 변경사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/flux/.workshop/terraform)에서 확인할 수 있습니다.

:::

Flux는 Git 리포지토리와 같은 소스 제어 하에 유지되는 구성과 Kubernetes 클러스터를 동기화 상태로 유지하고, 배포할 새로운 코드가 있을 때 해당 구성에 대한 업데이트를 자동화합니다. Kubernetes의 API 확장 서버를 사용하여 구축되었으며, Prometheus 및 Kubernetes 에코시스템의 다른 핵심 구성 요소와 통합할 수 있습니다. Flux는 멀티 테넌시를 지원하고 임의의 수의 Git 리포지토리를 동기화합니다.

