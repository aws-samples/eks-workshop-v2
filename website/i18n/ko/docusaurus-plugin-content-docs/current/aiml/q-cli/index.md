---
title: "Amazon Q CLI로 EKS 운영하기"
sidebar_position: 10
chapter: true
sidebar_custom_props: { "module": true }
description: "Amazon EKS MCP 서버와 함께 Amazon Q CLI를 사용하여 Amazon EKS 클러스터를 관리합니다."
tmdTranslationSourceHash: "00741618a8bafac98d4dc03bcc51a8df"
---

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=300 wait=30
$ prepare-environment aiml/q-cli
```

이 명령은 실습 환경에 다음과 같은 변경사항을 적용합니다:

- Carts 애플리케이션을 위한 DynamoDB 테이블 생성
- DynamoDB 테이블을 위한 KMS 키 생성
- DynamoDB 테이블이 KMS 키를 사용할 수 있도록 IAM 역할 및 정책 생성
- Carts 애플리케이션이 DynamoDB 테이블에 액세스할 수 있도록 EKS Pod Identity 설정 구성

이러한 변경사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/aiml/q-cli/.workshop/terraform)에서 확인할 수 있습니다.
:::

[Amazon Q Developer의 커맨드 라인 인터페이스(CLI) 에이전트](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing.html)는 고급 AI 어시스턴트의 강력한 기능을 커맨드 라인 환경에 직접 제공하여 소프트웨어 개발 경험을 혁신합니다. 이 에이전트는 자연어 이해와 컨텍스트 인식을 활용하여 복잡한 작업을 더 효율적으로 수행할 수 있도록 도와줍니다. Amazon EKS를 위한 서버를 포함한 [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) 서버 세트와 통합되어 강력한 개발 도구에 액세스할 수 있습니다. 다중 턴 대화 지원을 통해 에이전트와 협업적으로 상호 작용할 수 있어 더 짧은 시간에 더 많은 작업을 수행할 수 있습니다.

이 섹션에서는 다음을 학습합니다:

- 환경에서 Amazon Q CLI 구성하기
- Amazon EKS용 MCP 서버 설정하기
- Amazon Q CLI를 사용하여 EKS 클러스터 세부 정보 검색하기
- Amazon Q CLI를 사용하여 Amazon EKS에 애플리케이션 배포하기
- Amazon Q CLI를 사용하여 Amazon EKS의 워크로드 문제 해결하기

:::caution 미리보기
이 모듈은 현재 미리보기 단계이며, 발생한 [모든 문제를 보고](https://github.com/aws-samples/eks-workshop-v2/issues)해 주시기 바랍니다.
:::

