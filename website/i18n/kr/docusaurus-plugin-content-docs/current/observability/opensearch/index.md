---
title: "OpenSearch를 통한 옵저버빌러티"
sidebar_position: 35
sidebar_custom_props: { "module": true }
description: "OpenSearch를 중심으로 Amazon Elastic Kubernetes Service(EKS)의 관측성 기능을 구축합니다."
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비하세요:

```bash timeout=3600 wait=30
$ prepare-environment observability/opensearch
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

- 이전 EKS 워크샵 모듈의 리소스 정리
- Amazon OpenSearch Service 도메인 프로비저닝 (아래 **참고** 확인)
- CloudWatch Logs에서 OpenSearch로 EKS 컨트롤 플레인 로그를 내보내는 데 사용되는 Lambda 함수 설정

**참고**: AWS 이벤트에 참여하시는 경우, 시간 절약을 위해 OpenSearch 도메인이 사전에 프로비저닝되어 있습니다. 반면에 자체 계정에서 이 지침을 따르는 경우, `prepare-environment` 단계에서 OpenSearch 도메인을 프로비저닝하며, 이는 최대 30분이 소요될 수 있습니다.

이러한 변경사항을 적용하는 Terraform 코드는 [여기](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/opensearch/.workshop/terraform)에서 확인할 수 있습니다.

:::

이 실습에서는 관측성을 위한 [OpenSearch](https://opensearch.org/about.html)의 사용에 대해 살펴볼 것입니다. OpenSearch는 데이터를 수집, 검색, 시각화 및 분석하는 데 사용되는 커뮤니티 주도의 오픈소스 검색 및 분석 제품군입니다. OpenSearch는 데이터 저장소와 검색 엔진(OpenSearch), 시각화 및 사용자 인터페이스(OpenSearch Dashboards), 그리고 서버 측 데이터 수집기(Data Prepper)로 구성됩니다. 우리는 대화형 로그 분석, 실시간 애플리케이션 모니터링, 검색 등을 쉽게 수행할 수 있게 해주는 관리형 서비스인 [Amazon OpenSearch Service](https://aws.amazon.com/opensearch-service/)를 사용할 것입니다.

Kubernetes 이벤트, 컨트롤 플레인 로그 및 파드 로그가 Amazon EKS에서 Amazon OpenSearch Service로 내보내져, 두 Amazon 서비스가 관측성 향상을 위해 어떻게 함께 사용될 수 있는지 보여줍니다.