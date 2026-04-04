---
title: "소개"
sidebar_position: 21
tmdTranslationSourceHash: 'f891bd52e91f7dbf2c8700666e52da5e'
---

우리 아키텍처의 `carts` 컴포넌트는 Amazon DynamoDB를 스토리지 백엔드로 사용하며, 이는 Amazon EKS와 비관계형 데이터베이스 통합에서 흔히 볼 수 있는 사용 사례입니다. 현재 carts API가 배포된 방식은 EKS 클러스터에서 컨테이너로 실행되는 [경량 버전의 Amazon DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html)를 사용합니다.

다음 명령을 실행하여 이를 확인할 수 있습니다:

```bash
$ kubectl -n carts get pod
NAME                              READY   STATUS    RESTARTS        AGE
carts-5d7fc9d8f-xm4hs             1/1     Running   0               14m
carts-dynamodb-698674dcc6-hw2bg   1/1     Running   0               14m
```

위의 경우, Pod `carts-dynamodb-698674dcc6-hw2bg`가 우리의 경량 DynamoDB 서비스입니다. 환경을 검사하여 `carts` 애플리케이션이 이것을 사용하고 있는지 확인할 수 있습니다:

```bash
$ kubectl -n carts exec deployment/carts -- env | grep RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT
RETAIL_CART_PERSISTENCE_DYNAMODB_ENDPOINT=http://carts-dynamodb:8000
```

이 접근 방식은 테스트에 유용할 수 있지만, 완전 관리형 Amazon DynamoDB 서비스가 제공하는 확장성과 안정성의 이점을 최대한 활용하기 위해 애플리케이션을 마이그레이션하려고 합니다.

