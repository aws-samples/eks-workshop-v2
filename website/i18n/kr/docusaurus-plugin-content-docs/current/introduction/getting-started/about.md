---
title: 셈플 어플리케이션
sidebar_position: 10
---

이 워크샵의 대부분의 실습에서는 실제 실습 중에 작업할 수 있는 컨테이너 컴포넌트를 제공하는 공통 샘플 애플리케이션을 사용합니다. 이 샘플 애플리케이션은 고객이 카탈로그를 탐색하고, 장바구니에 항목을 추가하고, 체크아웃 프로세스를 통해 주문을 완료할 수 있는 간단한 웹 스토어 애플리케이션을 모델링합니다.

<Browser url="-">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

이 애플리케이션에는 다음과 같은 여러 컴포넌트와 종속성이 있습니다:

<Browser url="-">
<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>
</Browser>

| Component     | Description                                         |
| ------------- | --------------------------------------------------- |
| UI            | 프론트엔드 사용자 인터페이스를 제공하고 다양한 다른 서비스에 대한 API 호출을 집계합니다. |
| Catalog       | 제품 목록 및 상세 정보를 위한 API                               |
| Cart          | 고객 장바구니를 위한 API                                     |
| Checkout      | 체크아웃 프로세스를 조율하기 위한 API                              |
| Orders        | 고객 주문을 수신하고 처리하기 위한 API                             |
| Static assets | 제품 카탈로그와 관련된 이미지와 같은 정적 자산을 제공합니다                   |

처음에는 로드 밸런서나 관리형 데이터베이스와 같은 AWS 서비스를 사용하지 않고, Amazon EKS 클러스터 내에서 자체적으로 완결된 방식으로 애플리케이션을 배포할 것입니다. 실습을 진행하면서 EKS의 다양한 기능을 활용하여 우리의 리테일 스토어를 위한 더 광범위한 AWS 서비스와 기능을 활용하게 될 것입니다.

[GitHub](https://github.com/aws-containers/retail-store-sample-app)에서 샘플 애플리케이션의 전체 소스 코드를 확인할 수 있습니다.