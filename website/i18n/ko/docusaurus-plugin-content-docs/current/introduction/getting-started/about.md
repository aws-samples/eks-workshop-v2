---
title: 샘플 애플리케이션
sidebar_position: 10
tmdTranslationSourceHash: 583977cbf40b8bd4fc4e0c9fbe10215b
---

이 워크샵의 대부분의 실습은 공통 샘플 애플리케이션을 사용하여 실제 컨테이너 컴포넌트를 제공하므로 실습 중에 작업할 수 있습니다. 샘플 애플리케이션은 고객이 카탈로그를 탐색하고, 장바구니에 항목을 추가하고, 체크아웃 프로세스를 통해 주문을 완료할 수 있는 간단한 웹 스토어 애플리케이션을 모델링합니다.

<Browser url="-">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

애플리케이션은 여러 컴포넌트와 종속성을 가지고 있습니다:

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

| 컴포넌트 | 설명                                                                                   |
| --------- | --------------------------------------------------------------------------------------------- |
| UI        | 프론트엔드 사용자 인터페이스를 제공하고 다양한 다른 서비스에 대한 API 호출을 집계합니다. |
| Catalog   | 제품 목록 및 세부 정보를 위한 API                                                          |
| Cart      | 고객 장바구니를 위한 API                                                       |
| Checkout  | 체크아웃 프로세스를 조율하는 API                                                       |
| Orders    | 고객 주문을 수신하고 처리하는 API                                                    |

처음에는 로드 밸런서나 관리형 데이터베이스와 같은 AWS 서비스를 사용하지 않고 Amazon EKS 클러스터에 독립적으로 포함된 방식으로 애플리케이션을 배포합니다. 실습을 진행하면서 EKS의 다양한 기능을 활용하여 소매점을 위한 광범위한 AWS 서비스와 기능을 활용할 것입니다.

샘플 애플리케이션의 전체 소스 코드는 [GitHub](https://github.com/aws-containers/retail-store-sample-app)에서 찾을 수 있습니다.

