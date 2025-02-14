---
title: "소개"
sidebar_position: 10
---

우리 아키텍처의 `catalog` 컴포넌트는 MySQL 데이터베이스를 스토리지 백엔드로 사용합니다. 현재 catalog API가 배포되는 방식은 EKS 클러스터 내의 Pod로 배포된 데이터베이스를 사용합니다.

다음 명령어를 실행하여 이를 확인할 수 있습니다:

```bash
$ kubectl -n catalog get pod
NAME                              READY   STATUS    RESTARTS        AGE
catalog-5d7fc9d8f-xm4hs             1/1     Running   0               14m
catalog-mysql-0                     1/1     Running   0               14m
```

위의 경우, `catalog-mysql-0` Pod는 MySQL Pod입니다. 우리의 `catalog` 애플리케이션이 이를 사용하고 있는지 환경을 검사하여 확인할 수 있습니다:

```bash
$ kubectl -n catalog exec deployment/catalog -- env \
  | grep DB_ENDPOINT
DB_ENDPOINT=catalog-mysql:3306
```

우리는 Amazon RDS 서비스가 제공하는 확장성과 안정성을 최대한 활용하기 위해 애플리케이션을 완전 관리형 Amazon RDS 서비스로 마이그레이션하고자 합니다.