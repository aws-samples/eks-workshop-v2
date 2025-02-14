---
title: "Composition 생성하기"
sidebar_position: 10
---

`CompositeResourceDefinition`(XRD)는 Composite Resource(XR)의 유형과 스키마를 정의합니다. XRD는 원하는 XR과 그 필드에 대해 Crossplane에 알려줍니다. XRD는 CustomResourceDefinition(CRD)과 유사하지만 더 체계적인 구조를 가지고 있습니다. XRD를 생성하는 것은 주로 OpenAPI ["구조적 스키마"](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)를 지정하는 것을 포함합니다.

애플리케이션 팀 구성원이 각자의 네임스페이스에서 DynamoDB 테이블을 생성할 수 있도록 하는 정의부터 시작해보겠습니다. 이 예제에서 사용자는 **이름**, **키 속성**, **인덱스 이름** 필드만 지정하면 됩니다.

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/definition.yaml
```

Composition은 Composite Resource가 생성될 때 취해야 할 조치에 대해 Crossplane에 알려줍니다. 각 Composition은 XR과 하나 이상의 Managed Resource 집합 사이의 연결을 설정합니다. XR이 생성, 업데이트 또는 삭제될 때, 연관된 Managed Resource도 그에 따라 생성, 업데이트 또는 삭제됩니다.

다음 Composition은 managed resource `Table`을 프로비저닝합니다:

```file
manifests/modules/automation/controlplanes/crossplane/compositions/composition/table.yaml
```

이 구성을 EKS 클러스터에 적용해보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/crossplane/compositions/composition
compositeresourcedefinition.apiextensions.crossplane.io/xdynamodbtables.awsblueprints.io created
composition.apiextensions.crossplane.io/table.dynamodb.awsblueprints.io created
```

이러한 리소스들을 배치함으로써, DynamoDB 테이블을 생성하기 위한 Crossplane Composition을 성공적으로 설정했습니다. 이 추상화를 통해 애플리케이션 개발자들은 기본 AWS 관련 세부사항을 이해할 필요 없이 표준화된 DynamoDB 테이블을 프로비저닝할 수 있습니다.