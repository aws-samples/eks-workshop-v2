---
title: "간단한 정책 생성하기"
sidebar_position: 71
tmdTranslationSourceHash: '5082eba1f15e9129c8ebc5336dd53c3d'
---

Kyverno는 두 가지 종류의 정책 리소스를 제공합니다: 클러스터 전체 리소스에 사용되는 **ClusterPolicy**와 네임스페이스 리소스에 사용되는 **Policy**입니다. Kyverno 정책에 대한 이해를 돕기 위해, Deployment에 대한 레이블 요구사항으로 실습을 시작하겠습니다.

다음은 Pod 템플릿에 `CostCenter` 레이블이 없는 모든 Deployment를 차단하는 `ClusterPolicy` 샘플입니다:

::yaml{file="manifests/modules/security/kyverno/simple-policy/require-labels-policy.yaml" paths="spec.validationFailureAction,spec.rules,spec.rules.0.match,spec.rules.0.validate,spec.rules.0.validate.allowExistingViolations,spec.rules.0.validate.message,spec.rules.0.validate.pattern"}

1. `spec.validationFailureAction`은 검증 중인 리소스가 허용되지만 보고되어야 하는지(`Audit`) 또는 차단되어야 하는지(`Enforce`)를 Kyverno에 지시합니다. 기본값은 `Audit`이지만, 예제에서는 `Enforce`로 설정되어 있습니다
2. `rules` 섹션에는 검증할 하나 이상의 규칙이 포함됩니다
3. `match` 문은 확인할 범위를 설정합니다. 이 경우 모든 `Deployment` 리소스입니다
4. `validate` 문은 정의된 내용을 긍정적으로 확인하려고 시도합니다. 요청된 리소스와 비교했을 때 문이 참이면 허용됩니다. 거짓이면 차단됩니다
5. `allowExistingViolations: false`는 이미 위반 중인 Deployment에 대한 업데이트도 차단되도록 보장합니다. 기본적으로 Kyverno는 정책이 적용되기 전에 존재했던 비준수 리소스에 대한 업데이트를 허용하여 워크로드 중단을 방지합니다 — 이를 `false`로 설정하면 이 격차를 해소하고 모든 승인 요청에 대해 정책을 엄격하게 시행합니다
6. `message`는 이 규칙이 검증에 실패할 경우 사용자에게 표시되는 내용입니다
7. `pattern` 객체는 리소스에서 확인할 패턴을 정의합니다. 이 경우 `CostCenter`가 포함된 `spec.template.metadata.labels`를 찾습니다 — Deployment 사양 내부의 Pod 템플릿 레이블

다음 명령을 사용하여 정책을 생성합니다:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/simple-policy/require-labels-policy.yaml

clusterpolicy.kyverno.io/require-labels created
```

다음으로 `ui` Deployment를 살펴보고 Pod 템플릿 레이블을 확인합니다:

```bash
$ kubectl -n ui get deployment ui -o jsonpath='{.spec.template.metadata.labels}' | jq
{
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui"
}
```

Pod 템플릿에 필수 `CostCenter` 레이블이 없습니다. 이제 `ui` Deployment의 롤아웃을 강제로 실행해 봅시다:

```bash hook=labels-blocked expectError=true
$ kubectl -n ui rollout restart deployment/ui
error: failed to patch: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/ui/ui was blocked due to the following policies

require-labels:
  check-team: 'validation error: Label ''CostCenter'' is required on the Deployment
    pod template. rule check-team failed at path /spec/template/metadata/labels/CostCenter/'
```

롤아웃이 실패했고 승인 웹훅이 require-labels Kyverno 정책으로 인해 요청을 거부했습니다.

이제 정책에서 정의한 필수 레이블 `CostCenter`를 아래의 Kustomization 패치를 사용하여 `ui` Deployment에 추가합니다:

```kustomization
modules/security/kyverno/simple-policy/ui-labeled/deployment.yaml
Deployment/ui
```

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/kyverno/simple-policy/ui-labeled
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
$ kubectl -n ui rollout status deployment/ui
deployment "ui" successfully rolled out
$ kubectl -n ui get deployment ui -o jsonpath='{.spec.template.metadata.labels}' | jq
{
  "CostCenter": "IT",
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "ui",
  "app.kubernetes.io/name": "ui"
}
```

정책이 충족되었고 롤아웃이 성공했습니다.

### Mutating 규칙

위의 예제에서는 `validationFailureAction`에 정의된 기본 동작으로 검증 정책이 어떻게 작동하는지 확인했습니다. 그러나 Kyverno는 정책 내에서 Mutating 규칙을 관리하여 Kubernetes 리소스에 지정된 요구사항을 충족하거나 시행하도록 API 요청을 수정하는 데에도 사용할 수 있습니다. 리소스 변경은 검증 전에 발생하므로 검증 규칙이 변경 섹션에서 수행된 변경 사항과 충돌하지 않습니다.

다음은 변경 규칙이 정의된 정책 샘플입니다:

::yaml{file="manifests/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml" paths="spec.rules.0.match,spec.rules.0.mutate"}

1. `match.any.resources.kinds: [Deployment]`는 이 `ClusterPolicy`를 클러스터 전체의 모든 Deployment 리소스에 대상으로 지정합니다
2. `mutate`는 생성 중에 리소스를 수정합니다(차단/허용하는 validate와 달리). `patchStrategicMerge.spec.template.metadata.labels.CostCenter: IT`는 모든 Deployment의 Pod 템플릿 레이블에 `CostCenter: IT`를 자동으로 추가합니다

다음 명령을 사용하여 위 정책을 생성합니다:

```bash
$ kubectl apply -f  ~/environment/eks-workshop/modules/security/kyverno/simple-policy/add-labels-mutation-policy.yaml

clusterpolicy.kyverno.io/add-labels created
```

Mutation 웹훅을 검증하기 위해, 레이블을 명시적으로 추가하지 않고 `carts` Deployment를 롤아웃해 봅시다:

```bash
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
$ kubectl -n carts rollout status deployment/carts
deployment "carts" successfully rolled out
```

정책 요구사항을 충족하기 위해 `CostCenter=IT` 레이블이 `carts` Deployment Pod 템플릿에 자동으로 추가되었는지 검증합니다:

```bash
$ kubectl -n carts get deployment carts -o jsonpath='{.spec.template.metadata.labels}' | jq
{
  "CostCenter": "IT",
  "app.kubernetes.io/component": "service",
  "app.kubernetes.io/created-by": "eks-workshop",
  "app.kubernetes.io/instance": "carts",
  "app.kubernetes.io/name": "carts"
}
```

레이블이 `carts` Deployment의 Pod 템플릿에 자동으로 주입되었습니다. Kyverno 정책에서 `patchStrategicMerge` 및 `patchesJson6902` 매개변수를 사용하여 Amazon EKS 클러스터의 기존 리소스를 변경하는 것도 가능합니다.

이것은 Kyverno를 사용하여 Deployment를 검증하고 변경하는 간단한 예제였습니다. 다음 실습에서는 Pod Security Standards 시행 및 컨테이너 이미지 레지스트리 제한과 같은 고급 사용 사례를 살펴보겠습니다.

