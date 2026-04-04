---
title: "AWS CodePipeline"
sidebar_position: 5
sidebar_custom_props: { "module": true }
description: "AWS CodePipeline Amazon Elastic Kubernetes Service 액션."
tmdTranslationSourceHash: 'a4bce05779292471a1a1073eda371390'
---

:::tip 시작하기 전에

이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment automation/continuousdelivery/codepipeline
```

이 명령은 다음을 수행합니다:

- 컨테이너 이미지를 저장할 Amazon ECR 리포지토리 생성
- 이 실습을 위한 새로운 AWS CodePipeline 생성

:::

AWS CodePipeline은 소프트웨어를 릴리스하는 데 필요한 단계를 모델링, 시각화 및 자동화할 수 있는 지속적 배포 서비스입니다. AWS CodePipeline을 사용하면 코드 빌드, 사전 프로덕션 환경 배포, 애플리케이션 테스트 및 프로덕션 릴리스를 위한 전체 릴리스 프로세스를 모델링할 수 있습니다. 그런 다음 AWS CodePipeline은 코드가 변경될 때마다 정의된 워크플로에 따라 애플리케이션을 빌드, 테스트 및 배포합니다. 파트너 도구와 자체 커스텀 도구를 릴리스 프로세스의 모든 단계에 통합하여 엔드투엔드 지속적 배포 솔루션을 구성할 수 있습니다.

CodePipeline을 사용하면 컨테이너화된 애플리케이션의 소스 코드, 클러스터 구성, 컨테이너 이미지 빌드 및 이러한 이미지를 환경(EKS 클러스터)에 배포하는 것을 하나의 워크플로에서 관리할 수 있습니다.

