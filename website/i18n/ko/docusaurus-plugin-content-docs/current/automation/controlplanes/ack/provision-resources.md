---
title: "ACK 리소스 프로비저닝"
sidebar_position: 5
tmdTranslationSourceHash: '0aa3b23424b499ac70a2cbc57fa49081'
---

기본적으로 샘플 애플리케이션의 **Carts** 컴포넌트는 EKS 클러스터에서 Pod로 실행되는 DynamoDB local 인스턴스인 `carts-dynamodb`를 사용합니다. 이 실습 섹션에서는 Kubernetes 커스텀 리소스를 사용하여 애플리케이션용 Amazon DynamoDB 클라우드 기반 테이블을 프로비저닝하고, 로컬 복사본 대신 새로 프로비저닝된 DynamoDB 테이블을 사용하도록 **Carts** 배포를 구성할 것입니다.

![ACK reconciler 개념](/docs/automation/controlplanes/ack/ack-desired-current-ddb.webp)

Kubernetes 매니페스트를 사용하여 DynamoDB Table을 생성하는 방법을 살펴보겠습니다:

::yaml{file="manifests/modules/automation/controlplanes/ack/dynamodb/dynamodb-create.yaml" paths="apiVersion,kind,spec.keySchema,spec.attributeDefinitions,spec.billingMode,spec.tableName,spec.globalSecondaryIndexes"}

1. ACK DynamoDB 컨트롤러 사용
2. DynamoDB 테이블 리소스 생성
3. `id` 속성을 파티션 키(`HASH`)로 사용하여 기본 키 지정
4. `id`와 `customerId`를 문자열 속성으로 정의
5. 온디맨드 요금 모델 지정
6. `${EKS_CLUSTER_NAME}` 환경 변수 접두사를 사용하여 DynamoDB 테이블 이름 지정
7. 모든 테이블 속성이 프로젝션된 `customerID`로 효율적인 쿼리를 가능하게 하는 `idx_global_customerId`라는 글로벌 보조 인덱스 생성

:::info
주의 깊게 살펴본 분들은 YAML 사양이 `tableName` 및 `attributeDefinitions`와 같은 친숙한 필드를 포함하여 DynamoDB의 [API 서명](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_CreateTable.html)과 매우 유사하다는 것을 알 수 있습니다.
:::

이제 클러스터에 이러한 업데이트를 적용해 보겠습니다:

```bash wait=10
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/ack/dynamodb \
  | envsubst | kubectl apply -f-
table.dynamodb.services.k8s.aws/items created
```

클러스터의 ACK 컨트롤러는 이러한 새 리소스에 응답하고 매니페스트에서 정의한 AWS 인프라를 프로비저닝합니다. ACK가 테이블을 생성했는지 확인하려면 다음 명령을 실행하세요:

```bash timeout=300
$ kubectl wait table.dynamodb.services.k8s.aws items -n carts --for=condition=ACK.ResourceSynced --timeout=15m
table.dynamodb.services.k8s.aws/items condition met
$ kubectl get table.dynamodb.services.k8s.aws items -n carts -ojson | yq '.status."tableStatus"'
ACTIVE
```

마지막으로 AWS CLI를 사용하여 테이블이 생성되었는지 확인해 보겠습니다:

```bash
$ aws dynamodb list-tables

{
    "TableNames": [
        "eks-workshop-carts-ack"
    ]
}
```

이 출력은 새 테이블이 성공적으로 생성되었음을 확인합니다!

ACK를 활용하여 Kubernetes 클러스터에서 직접 클라우드 기반 DynamoDB 테이블을 원활하게 프로비저닝했으며, 이는 AWS 리소스를 관리하는 이 접근 방식의 강력함과 유연성을 보여줍니다.

