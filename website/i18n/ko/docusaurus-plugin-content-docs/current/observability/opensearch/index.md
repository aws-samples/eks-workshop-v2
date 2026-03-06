---
title: "OpenSearch를 활용한 관측 가능성"
sidebar_position: 35
sidebar_custom_props: { "module": true }
description: "OpenSearch를 중심으로 Amazon Elastic Kubernetes Service의 관측 가능성 기능을 구축합니다."
tmdTranslationSourceHash: "1c8c349b1fcc283207a7fba13ee5879a"
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=3600 wait=30
$ prepare-environment observability/opensearch
```

이 명령은 다음과 같은 변경사항을 랩 환경에 적용합니다:

- 이전 EKS 워크샵 모듈의 리소스 정리
- Amazon OpenSearch Service 도메인 프로비저닝 (아래 **참고** 참조)
- CloudWatch Logs에서 OpenSearch로 EKS control plane 로그를 내보내는 데 사용되는 Lambda 함수 설정

**참고**: AWS 이벤트에 참여하는 경우, 시간을 절약하기 위해 OpenSearch 도메인이 미리 프로비저닝되어 있습니다. 반면에 자체 계정에서 이 지침을 따르는 경우, 위의 `prepare-environment` 단계에서 OpenSearch 도메인을 프로비저닝하며, 완료하는 데 최대 30분이 소요될 수 있습니다.

이러한 변경사항을 적용하는 Terraform은 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/opensearch/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 관측 가능성을 위한 [OpenSearch](https://opensearch.org/about.html)의 사용을 살펴봅니다. OpenSearch는 커뮤니티 기반의 오픈 소스 검색 및 분석 제품군으로, 데이터를 수집, 검색, 시각화 및 분석하는 데 사용됩니다. OpenSearch는 데이터 저장소 및 검색 엔진(OpenSearch), 시각화 및 사용자 인터페이스(OpenSearch Dashboards), 서버 측 데이터 수집기(Data Prepper)로 구성됩니다. [Amazon OpenSearch Service](https://aws.amazon.com/opensearch-service/)를 사용할 것이며, 이는 대화형 로그 분석, 실시간 애플리케이션 모니터링, 검색 등을 쉽게 수행할 수 있도록 하는 관리형 서비스입니다.

Kubernetes events, control plane 로그 및 Pod 로그가 Amazon EKS에서 Amazon OpenSearch Service로 내보내져 두 Amazon 서비스가 함께 사용되어 관측 가능성을 개선하는 방법을 보여줍니다.

