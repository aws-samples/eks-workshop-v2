---
title: "Composition"
sidebar_position: 30
tmdTranslationSourceHash: '37595511877026b26658b23b9abddbbf'
---

개별 클라우드 리소스를 프로비저닝하는 것 외에도 Crossplane은 Composition이라는 더 높은 수준의 추상화를 제공합니다. Composition을 사용하면 클라우드 리소스 배포를 위한 독단적인 템플릿을 생성할 수 있습니다. 이 기능은 다음과 같이 인프라 전반에 걸쳐 특정 요구 사항을 적용해야 하는 조직에 특히 유용합니다:

- 모든 AWS 리소스에 특정 태그가 있는지 확인
- 모든 Amazon Simple Storage Service (S3) 버킷에 특정 암호화 키 적용
- 조직 전반에 걸쳐 리소스 구성 표준화

Composition을 사용하면 플랫폼 팀은 이러한 템플릿을 통해 생성된 모든 리소스가 조직의 요구 사항을 충족하도록 보장하는 셀프 서비스 API 추상화를 정의할 수 있습니다. 이 접근 방식은 리소스 관리를 간소화하고 배포 전반에 걸쳐 일관성을 보장합니다.

이 랩 섹션에서는 Amazon DynamoDB 테이블을 Crossplane Composition으로 패키징하는 방법을 살펴봅니다. 이를 통해 기본 구성에 대한 제어를 유지하면서 개발 팀이 더 쉽게 사용할 수 있는 리소스를 만드는 방법을 보여줍니다.

Composition을 활용하여 다음을 수행하는 방법을 살펴보겠습니다:

1. DynamoDB 테이블에 대한 표준화된 템플릿 정의
2. 개발자를 위한 리소스 생성 프로세스 간소화
3. 조직 정책 및 모범 사례 준수 보장

이 실습을 통해 Crossplane Composition에 대한 실질적인 경험을 얻고 Kubernetes 환경 내에서 클라우드 리소스를 관리하는 데 있어 이들의 이점을 이해하게 될 것입니다.

