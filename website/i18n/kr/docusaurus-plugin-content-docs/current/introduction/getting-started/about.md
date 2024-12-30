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

| Component     | Description                                                     |
| ------------- | --------------------------------------------------------------- |
| UI            | 프론트엔드 사용자 인터페이스를 제공하고 다양한 다른 서비스에 대한 API 호출을 집계합니다.             |
| Catalog       | 제품 목록 및 상세 정보를 위한 API                                           |
| Cart          | 고객 장바구니를 위한 API                                                 |
| Checkout      | 체크아웃 프로세스를 조율하기 위한 API                                          |
| Orders        | 고객 주문을 수신하고 처리하기 위한 API                                         |
| Static assets | Serves static assets like images related to the product catalog |

Initially we'll deploy the application in a manner that is self-contained in the Amazon EKS cluster, without using any AWS services like load balancers or a managed database. Over the course of the labs we'll leverage different features of EKS to take advantage of broader AWS services and features for our retail store.

You can find the full source code for the sample application on [GitHub](https://github.com/aws-containers/retail-store-sample-app).