---
title: "Flux"
sidebar_position: 2
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service(EKS)에서 Flux를 사용하여 지속적이고 점진적인 배포를 구현합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=300 wait=30
$ prepare-environment automation/gitops/flux
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- AWS CodeCommit 리포지토리 생성
- CodeCommit 리포지토리에 접근 권한이 있는 IAM 사용자 생성
- [샘플 애플리케이션 UI 컴포넌트](https://github.com/aws-containers/retail-store-sample-app)를 위한 지속적 통합 파이프라인 생성

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/gitops/flux/.workshop/terraform)에서 확인할 수 있습니다.

:::

Flux는 Git 리포지토리와 같은 소스 제어 하에 있는 구성과 Kubernetes 클러스터를 동기화 상태로 유지하며, 배포할 새로운 코드가 있을 때 해당 구성에 대한 업데이트를 자동화합니다. Kubernetes API 확장 서버를 사용하여 구축되었으며, Prometheus 및 다른 Kubernetes 생태계의 핵심 구성 요소들과 통합될 수 있습니다. Flux는 멀티 테넌시를 지원하고 임의의 수의 Git 리포지토리를 동기화할 수 있습니다.