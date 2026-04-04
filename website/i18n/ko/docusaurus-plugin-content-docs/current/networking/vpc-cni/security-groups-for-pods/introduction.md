---
title: "소개"
sidebar_position: 10
tmdTranslationSourceHash: '5d5cdf0aa50b19d179ab2651fb0e3e11'
---

아키텍처의 `catalog` 컴포넌트는 MySQL 데이터베이스를 스토리지 백엔드로 사용합니다. 현재 catalog API는 EKS 클러스터 내에서 Pod로 실행되는 데이터베이스와 함께 배포되어 있습니다.

다음 명령을 실행하여 이를 확인할 수 있습니다:

```bash
$ kubectl -n catalog get pod
NAME                                READY   STATUS    RESTARTS        AGE
catalog-5d7fc9d8f-xm4hs             1/1     Running   0               14m
catalog-mysql-0                     1/1     Running   0               14m
```

위 출력에서 `catalog-mysql-0` Pod가 MySQL 데이터베이스입니다. `catalog` 애플리케이션이 이를 사용하고 있는지 환경을 검사하여 확인할 수 있습니다:

```bash
$ kubectl -n catalog exec deployment/catalog -- env \
  | grep RETAIL_CATALOG_PERSISTENCE_ENDPOINT
RETAIL_CATALOG_PERSISTENCE_ENDPOINT=catalog-mysql:3306
```

확장성과 안정성 기능을 활용하기 위해 애플리케이션을 완전 관리형 Amazon RDS 서비스를 사용하도록 마이그레이션하려고 합니다.

