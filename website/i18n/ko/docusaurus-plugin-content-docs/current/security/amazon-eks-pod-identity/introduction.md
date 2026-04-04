---
title: "소개"
sidebar_position: 31
tmdTranslationSourceHash: 'c68e095ef9e36a70423411002c0c5401'
---

아키텍처의 `carts` 컴포넌트는 Amazon DynamoDB를 스토리지 백엔드로 사용하며, 이는 Amazon EKS와 비관계형 데이터베이스 통합에서 흔히 볼 수 있는 사용 사례입니다. 현재 carts API는 EKS 클러스터 내 컨테이너로 실행되는 [경량 버전의 Amazon DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html)와 함께 배포되어 있습니다.

다음 명령을 실행하여 이를 확인할 수 있습니다:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS        AGE
carts-5d7fc9d8f-xm4hs             1/1     Running   0               14m
carts-dynamodb-698674dcc6-hw2bg   1/1     Running   0               14m
```

위 출력에서 `carts-dynamodb-698674dcc6-hw2bg` Pod가 경량 DynamoDB 서비스입니다. 다음과 같이 환경을 검사하여 `carts` 애플리케이션이 이를 사용하고 있는지 확인할 수 있습니다:

```bash
$ kubectl -n carts exec deployment/carts -- env | grep RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT
RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT=http://carts-dynamodb:8000
```

이 접근 방식은 테스트에 유용할 수 있지만, 완전 관리형 Amazon DynamoDB 서비스로 애플리케이션을 마이그레이션하여 제공하는 확장성과 안정성을 최대한 활용하고자 합니다. 다음 섹션에서는 Amazon DynamoDB를 사용하도록 애플리케이션을 재구성하고 EKS Pod Identity를 구현하여 AWS 서비스에 대한 안전한 액세스를 제공할 것입니다.

