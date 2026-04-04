---
title: "Managed Resources"
sidebar_position: 20
tmdTranslationSourceHash: b87b841cd6de246ccbdc2b50c39813bf
---

기본적으로 샘플 애플리케이션의 **Carts** 컴포넌트는 EKS 클러스터에서 Pod로 실행되는 DynamoDB 로컬 인스턴스인 `carts-dynamodb`를 사용합니다. 이 실습 섹션에서는 Crossplane managed resources를 사용하여 애플리케이션을 위한 Amazon DynamoDB 클라우드 기반 테이블을 프로비저닝하고, 로컬 복사본 대신 새로 프로비저닝된 DynamoDB 테이블을 사용하도록 **Carts** 배포를 구성하겠습니다.

![Crossplane reconciler concept](/docs/automation/controlplanes/crossplane/Crossplane-desired-current-ddb.webp)

Crossplane managed resource 매니페스트를 통해 DynamoDB 테이블을 생성하는 방법을 살펴보겠습니다:

::yaml{file="manifests/modules/automation/controlplanes/crossplane/managed/table.yaml" paths="apiVersion,kind,metadata,spec.forProvider.attribute,spec.forProvider.hashKey,spec.forProvider.billingMode,spec.forProvider.globalSecondaryIndex,spec.providerConfigRef"}

1. Upbound의 AWS DynamoDB provider를 사용
2. DynamoDB 테이블 리소스 생성
3. 클러스터 접두사가 붙은 이름과 external name 어노테이션이 있는 Kubernetes 객체 지정
4. `id`와 `customerId`를 문자열(`S`) 타입 속성으로 정의
5. `id`를 기본 파티션 키로 설정
6. 온디맨드 요금 모델 지정
7. 모든 속성이 프로젝션된 `customerId`에 대한 글로벌 보조 인덱스 생성
8. 인증을 위해 AWS provider 구성 참조

이제 `dynamodb.aws.upbound.io` 리소스를 사용하여 DynamoDB 테이블 구성을 생성할 수 있습니다.

```bash wait=10 timeout=400 hook=table
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/managed \
  | envsubst | kubectl apply -f-
table.dynamodb.aws.upbound.io/eks-workshop-carts-crossplane created
$ kubectl wait tables.dynamodb.aws.upbound.io ${EKS_CLUSTER_NAME}-carts-crossplane \
  --for=condition=Ready --timeout=5m
```

AWS 관리형 서비스를 프로비저닝하는 데 시간이 걸리며, DynamoDB의 경우 최대 2분까지 소요됩니다. Crossplane은 Kubernetes 커스텀 리소스의 `status` 필드에 reconciliation 상태를 보고합니다.

```bash
$ kubectl get tables.dynamodb.aws.upbound.io
NAME                                        READY  SYNCED   EXTERNAL-NAME                   AGE
eks-workshop-carts-crossplane               True   True     eks-workshop-carts-crossplane   6s
```

이 구성이 적용되면 Crossplane은 AWS에 DynamoDB 테이블을 생성하며, 이는 애플리케이션에서 사용할 수 있습니다. 다음 섹션에서는 이 새로 생성된 테이블을 사용하도록 애플리케이션을 업데이트하겠습니다.

