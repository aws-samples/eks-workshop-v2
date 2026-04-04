---
title: "작동 방식"
sidebar_position: 5
tmdTranslationSourceHash: '318ab5fd6c8856bb1f1e75f36368450c'
---

Crossplane은 두 가지 주요 구성 요소를 사용하여 클러스터 내에서 작동합니다:

1. 핵심 기능을 제공하는 Crossplane 컨트롤러
2. 하나 이상의 Crossplane 프로바이더, 각각 AWS와 같은 특정 프로바이더와 통합하기 위한 컨트롤러와 Custom Resource Definition을 제공

EKS 클러스터에는 Crossplane 컨트롤러, Upbound AWS 프로바이더 및 필요한 구성 요소가 사전 설치되어 있습니다. 이들은 `crossplane-system` 네임스페이스에서 `crossplane-rbac-manager`와 함께 배포로 실행됩니다:

```bash
$ kubectl get deployment -n crossplane-system
NAME                                         READY   UP-TO-DATE   AVAILABLE   AGE
crossplane                                   1/1     1            1           3h7m
crossplane-rbac-manager                      1/1     1            1           3h7m
upbound-aws-provider-dynamodb-23a48a51e223   1/1     1            1           3h6m
upbound-provider-family-aws-1ac09674120f     1/1     1            1           21h
```

여기서 `upbound-provider-family-aws`는 Upbound에서 개발하고 지원하는 Amazon Web Services (AWS)용 Crossplane 프로바이더를 나타냅니다. `upbound-aws-provider-dynamodb`는 Crossplane을 통해 DynamoDB를 배포하는 전용 하위 집합입니다.

Crossplane은 개발자가 클레임(claim)이라는 Kubernetes 매니페스트를 사용하여 인프라 리소스를 요청하는 프로세스를 단순화합니다. 아래 다이어그램에 표시된 것처럼, 클레임은 네임스페이스 범위의 유일한 Crossplane 리소스로, 개발자 인터페이스 역할을 하며 구현 세부 정보를 추상화합니다. 클레임이 클러스터에 배포되면 Composite Resource (XR)가 생성되는데, 이는 Composition이라는 템플릿을 통해 정의된 하나 이상의 클라우드 리소스를 나타내는 Kubernetes 커스텀 리소스입니다. Composite Resource는 하나 이상의 Managed Resource를 생성하며, 이는 AWS API와 상호 작용하여 원하는 인프라 리소스의 생성을 요청합니다.

![Crossplane claim](/docs/automation/controlplanes/crossplane/claim-architecture-drawing.webp)

이 아키텍처는 높은 수준의 추상화(클레임)로 작업하는 개발자와 기본 인프라 구현(Composition 및 Managed Resource)을 정의하는 플랫폼 팀 간의 명확한 관심사 분리를 가능하게 합니다.

