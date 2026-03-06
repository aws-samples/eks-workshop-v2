---
title: "Composition 생성하기"
sidebar_position: 10
tmdTranslationSourceHash: '641c30bbbdebb13b80074aaf46243eb8'
---

`CompositeResourceDefinition` (XRD)은 Composite Resource (XR)의 타입과 스키마를 정의합니다. 이것은 Crossplane에 원하는 XR과 그 필드에 대해 알려줍니다. XRD는 CustomResourceDefinition (CRD)과 유사하지만 더 의견이 반영된 구조를 가지고 있습니다. XRD를 생성하는 것은 주로 OpenAPI ["구조적 스키마"](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)를 지정하는 것을 포함합니다.

애플리케이션 팀 멤버들이 각자의 네임스페이스에 DynamoDB 테이블을 생성할 수 있도록 하는 정의를 제공하는 것으로 시작하겠습니다. 이 예시에서 사용자는 **이름**, **키 속성**, 그리고 **인덱스 이름** 필드만 지정하면 됩니다.

<details>
  <summary>전체 XRD 매니페스트 확장하기</summary>

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml"}

</details>

XRD 매니페스트에서 DynamoDB 관련 구성을 살펴볼 수 있습니다.

다음은 DynamoDB 테이블 이름 지정이 필요한 섹션입니다:

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.resourceConfig.properties.name.type" zoomBefore="9"}

이 섹션은 DynamoDB 테이블 키 속성 지정을 제공합니다:

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.dynamoConfig.properties.rangeKey" zoomBefore="20"}

이것은 Global Secondary Index 지정에 대한 섹션입니다:

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.dynamoConfig.properties.globalSecondaryIndex.type" zoomBefore="23"}

이것은 Local Secondary Index 지정에 대한 섹션입니다:

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml" zoomPath="spec.versions.0.schema.openAPIV3Schema.properties.spec.properties.dynamoConfig.properties.localSecondaryIndex.type" zoomBefore="19"}

Composition은 Composite Resource가 생성될 때 Crossplane이 수행해야 할 작업에 대해 알려줍니다. 각 Composition은 XR과 하나 이상의 Managed Resource 집합 간의 링크를 설정합니다. XR이 생성, 업데이트 또는 삭제되면 관련 Managed Resource들도 그에 따라 생성, 업데이트 또는 삭제됩니다.

<details>
  <summary>관리 리소스 `Table`을 프로비저닝하는 Composition을 보려면 확장하세요:</summary>

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml"}

</details>

이것을 여러 부분으로 나누어 살펴보면 더 잘 이해할 수 있습니다.

이 섹션은 XR의 `spec.name` 필드를 Managed Resource의 external-name 어노테이션에 매핑하며, Crossplane은 이를 사용하여 AWS의 실제 DynamoDB 테이블 이름을 설정합니다.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.patchSets.0.patches.1.toFieldPath" zoomBefore="2"}

이것은 XR에서 관리되는 DynamoDB 리소스로 모든 속성 정의를 전송하여, Crossplane이 적절한 데이터 타입으로 테이블 스키마를 생성할 수 있게 합니다.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.1.policy.mergeOptions" zoomBefore="4"}

이것은 XR의 첫 번째 속성을 DynamoDB 테이블의 기본 키 구조의 파티션 키(해시 키)로 매핑합니다.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.3.toFieldPath" zoomBefore="2"}

이것은 XR 사양에서 관리 리소스로 GSI 이름을 전송하여, Crossplane이 DynamoDB 테이블에 명명된 Global Secondary Index를 생성할 수 있게 합니다.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.8.toFieldPath" zoomBefore="2"}

이것은 XR에서 관리 리소스로 LSI 구성을 매핑하여, Crossplane이 지정된 이름과 속성으로 Local Secondary Index를 프로비저닝할 수 있게 합니다.

::yaml{file="manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml" zoomPath="spec.resources.0.patches.11.toFieldPath" zoomBefore="2"}


이제 이 구성을 EKS 클러스터에 적용해 보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/composition
compositeresourcedefinition.apiextensions.crossplane.io/xdynamodbtables.awsblueprints.io created
composition.apiextensions.crossplane.io/table.dynamodb.awsblueprints.io created
```

이러한 리소스가 준비되면, DynamoDB 테이블 생성을 위한 Crossplane Composition을 성공적으로 설정한 것입니다. 이 추상화는 애플리케이션 개발자들이 기본 AWS 관련 세부 사항을 이해할 필요 없이 표준화된 DynamoDB 테이블을 프로비저닝할 수 있게 해줍니다.

