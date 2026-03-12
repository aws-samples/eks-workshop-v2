---
title: "Cluster Access Management API"
sidebar_position: 10
sidebar_custom_props: { "module": true }
description: "AWS IAM 엔터티를 사용하여 Amazon Elastic Kubernetes Service에 대한 사용자 및 그룹 액세스를 제공하기 위해 AWS 자격 증명을 관리합니다."
tmdTranslationSourceHash: '8bdc151830673a1edfa62df4bf11ebfe'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment security/cam
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- 다양한 시나리오에 사용될 AWS IAM 역할 생성

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/security/cam/.workshop/terraform)에서 확인할 수 있습니다.
:::

이제 플랫폼 엔지니어링 팀은 별도의 자격 증명 공급자를 유지 관리하고 통합해야 하는 클러스터 관리자의 부담을 제거하고, AWS Identity and Access Management (IAM) 사용자 및 역할을 Kubernetes 클러스터와 간소화된 구성으로 사용할 수 있습니다. AWS IAM과 Amazon EKS 간의 통합을 통해 관리자는 IAM을 Kubernetes ID에 매핑하여 감사 로깅 및 다단계 인증과 같은 IAM 보안 기능을 활용할 수 있으며, 관리자가 클러스터 생성 중이나 생성 후에 EKS API를 통해 직접 승인된 IAM 주체와 관련 Kubernetes 권한을 완전히 정의할 수 있습니다.

이 장에서는 Cluster Access Management API가 어떻게 작동하는지 이해하고, 기존 자격 증명 매핑 제어를 새로운 모델로 변환하여 Amazon EKS 클러스터에 대한 인증 및 권한 부여를 원활하게 제공하는 방법을 배웁니다.

