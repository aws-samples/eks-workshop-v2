---
title: "Crossplane"
sidebar_position: 1
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Crossplane을 사용하여 클라우드 네이티브 컨트롤 플레인을 구축합니다."
tmdTranslationSourceHash: 'f6d69f91180d666646e4baf1d121461e'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=120
$ prepare-environment automation/controlplanes/crossplane
```

이 명령은 실습 환경에 다음과 같은 변경 사항을 적용합니다:

- Amazon EKS 클러스터에 Crossplane과 AWS provider를 설치합니다

이러한 변경 사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/automation/controlplanes/crossplane/.workshop/terraform)에서 확인할 수 있습니다.

:::

[Crossplane](https://crossplane.io/)은 Kubernetes 클러스터를 범용 컨트롤 플레인으로 전환하는 Cloud Native Computing Foundation (CNCF)의 오픈 소스 프로젝트입니다. 플랫폼 팀이 여러 벤더의 인프라를 조합하고 애플리케이션 팀이 코드를 작성하지 않고도 사용할 수 있는 상위 레벨의 셀프 서비스 API를 제공할 수 있게 합니다.

Crossplane은 Kubernetes 클러스터를 확장하여 모든 인프라 또는 관리형 서비스의 오케스트레이션을 지원합니다. Crossplane의 세분화된 리소스를 상위 레벨 추상화로 구성하여 즐겨 사용하는 도구와 기존 프로세스를 사용하여 버전 관리, 관리, 배포 및 사용할 수 있습니다.

![EKS with Dynamodb](/docs/automation/controlplanes/crossplane/eks-workshop-crossplane.webp)

Crossplane을 사용하면 다음과 같은 작업을 수행할 수 있습니다:

1. Kubernetes 클러스터에서 직접 클라우드 인프라를 프로비저닝하고 관리합니다
2. 복잡한 인프라 설정을 나타내는 사용자 정의 리소스를 정의합니다
3. 애플리케이션 개발자를 위한 인프라 관리를 간소화하는 추상화 레이어를 생성합니다
4. 여러 클라우드 제공자에 걸쳐 일관된 정책과 거버넌스를 구현합니다

이 모듈에서는 Crossplane을 사용하여 AWS 리소스를 관리하는 방법을 살펴보고, 특히 샘플 애플리케이션용 DynamoDB 테이블을 프로비저닝하고 구성하는 데 중점을 둡니다.

