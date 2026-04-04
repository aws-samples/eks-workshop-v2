---
title: "Argo CD"
sidebar_position: 3
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Argo CD를 사용한 선언적 GitOps 지속적 배포."
tmdTranslationSourceHash: '917f480cca3b58b603a5220f1d863e71'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=120
$ prepare-environment automation/gitops/argocd
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- Amazon EKS 클러스터에 AWS Load Balancer controller 설치
- EBS CSI driver를 위한 EKS 관리형 애드온 설치

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/argocd/.workshop/terraform)에서 확인할 수 있습니다.

:::

[Argo CD](https://argoproj.github.io/cd/)는 GitOps 원칙을 구현하는 Kubernetes용 선언적 지속적 배포 도구입니다. 클러스터 내에서 컨트롤러로 작동하며, Git 리포지토리의 변경 사항을 지속적으로 모니터링하고 Git 리포지토리에 정의된 원하는 상태와 일치하도록 애플리케이션을 자동으로 동기화합니다.

CNCF graduated 프로젝트인 Argo CD는 다음과 같은 주요 기능을 제공합니다:

- 배포 관리를 위한 직관적인 웹 UI
- 멀티 클러스터 구성 지원
- CI/CD 파이프라인과의 통합
- 강력한 접근 제어
- 드리프트 감지 기능
- 다양한 배포 전략 지원

Argo CD를 사용하면 Kubernetes 애플리케이션이 소스 구성과 일관성을 유지하도록 보장하고 원하는 상태와 실제 상태 간에 발생하는 모든 드리프트를 자동으로 수정할 수 있습니다.

