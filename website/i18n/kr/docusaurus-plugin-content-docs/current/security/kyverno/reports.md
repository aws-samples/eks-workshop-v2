---
title: "보고서 및 감사"
sidebar_position: 74
---

Kyverno는 Kubernetes Policy Working Group에서 정의한 개방형 형식을 사용하는 [정책 보고](https://kyverno.io/docs/policy-reports/) 도구를 포함합니다. 이러한 보고서는 클러스터의 사용자 정의 리소스로 배포됩니다. Kyverno는 클러스터에서 _CREATE_, _UPDATE_, _DELETE_와 같은 승인 작업이 수행될 때 이러한 보고서를 생성합니다. 또한 기존 리소스에 대한 정책을 검증하는 백그라운드 스캔의 결과로도 보고서가 생성됩니다.

이 워크샵 전반에 걸쳐 우리는 특정 규칙이 있는 여러 정책을 만들었습니다. 리소스가 정책 정의에 따라 하나 이상의 규칙과 일치하고 이를 위반하는 경우, 각 위반에 대해 보고서에 항목이 생성됩니다. 동일한 리소스가 여러 규칙과 일치하고 위반하는 경우 여러 항목이 생성될 수 있습니다. 리소스가 삭제되면 해당 항목도 보고서에서 제거됩니다. 이는 Kyverno 보고서가 항상 클러스터의 현재 상태를 나타내며 과거 정보는 기록하지 않는다는 것을 의미합니다.

앞서 논의한 대로 Kyverno에는 두 가지 유형의 `validationFailureAction`이 있습니다:

1. `Audit` 모드: 리소스 생성을 허용하고 정책 보고서에 해당 작업을 보고합니다.
2. `Enforce` 모드: 리소스 생성을 거부하지만 정책 보고서에 항목을 추가하지 않습니다.

예를 들어, `Audit` 모드의 정책에 모든 리소스가 `CostCenter` 레이블을 설정해야 하는 단일 규칙이 포함되어 있고, 해당 레이블 없이 Pod가 생성되는 경우, Kyverno는 Pod 생성을 허용하지만 규칙 위반으로 인해 정책 보고서에 `FAIL` 결과로 기록됩니다. 동일한 정책이 `Enforce` 모드로 구성된 경우, Kyverno는 즉시 리소스 생성을 차단하며, 이는 정책 보고서에 항목을 생성하지 않습니다. 하지만 Pod가 규칙을 준수하여 생성되면 보고서에 `PASS`로 보고됩니다. 차단된 작업은 작업이 요청된 네임스페이스의 Kubernetes 이벤트에서 확인할 수 있습니다.

이 워크샵에서 지금까지 생성한 정책에 대한 클러스터의 준수 상태를 정책 보고서를 검토하여 살펴보겠습니다.

```bash hook=reports
$ kubectl get policyreports -A

NAMESPACE     NAME                             PASS   FAIL   WARN   ERROR   SKIP   AGE
assets        cpol-baseline-policy             3      0      0      0       0      19m
assets        cpol-require-labels              0      3      0      0       0      27m
assets        cpol-restrict-image-registries   3      0      0      0       0      25m
carts         cpol-baseline-policy             6      0      0      0       0      19m
carts         cpol-require-labels              0      6      0      0       0      27m
carts         cpol-restrict-image-registries   3      3      0      0       0      25m
catalog       cpol-baseline-policy             5      0      0      0       0      19m
catalog       cpol-require-labels              0      5      0      0       0      27m
catalog       cpol-restrict-image-registries   5      0      0      0       0      25m
checkout      cpol-baseline-policy             6      0      0      0       0      19m
checkout      cpol-require-labels              0      6      0      0       0      27m
checkout      cpol-restrict-image-registries   6      0      0      0       0      25m
default       cpol-baseline-policy             2      0      0      0       0      19m
default       cpol-require-labels              2      0      0      0       0      13m
default       cpol-restrict-image-registries   1      1      0      0       0      13m
kube-system   cpol-baseline-policy             4      8      0      0       0      19m
kube-system   cpol-require-labels              0      12     0      0       0      27m
kube-system   cpol-restrict-image-registries   0      12     0      0       0      25m
kyverno       cpol-baseline-policy             24     0      0      0       0      19m
kyverno       cpol-require-labels              0      24     0      0       0      27m
kyverno       cpol-restrict-image-registries   0      24     0      0       0      25m
orders        cpol-baseline-policy             6      0      0      0       0      19m
orders        cpol-require-labels              0      6      0      0       0      27m
orders        cpol-restrict-image-registries   6      0      0      0       0      25m
rabbitmq      cpol-baseline-policy             2      0      0      0       0      19m
rabbitmq      cpol-require-labels              0      2      0      0       0      27m
rabbitmq      cpol-restrict-image-registries   2      0      0      0       0      25m
ui            cpol-baseline-policy             3      0      0      0       0      19m
ui            cpol-require-labels              0      3      0      0       0      27m
ui            cpol-restrict-image-registries   3      0      0      0       0      25m
```

> 참고: 출력은 다를 수 있습니다.

ClusterPolicy로 작업했기 때문에, 위의 출력에서 볼 수 있듯이 검증할 리소스를 생성한 `default` 네임스페이스뿐만 아니라 모든 네임스페이스에 걸쳐 보고서가 생성되었습니다. 보고서는 `PASS`, `FAIL`, `WARN`, `ERROR`, `SKIP`을 사용하여 객체의 상태를 보여줍니다.

앞서 언급했듯이 차단된 작업은 네임스페이스 이벤트에 기록됩니다. 다음 명령을 사용하여 이를 살펴보겠습니다:

```bash
$ kubectl get events | grep block
8m         Warning   PolicyViolation   clusterpolicy/restrict-image-registries   Pod default/nginx-public: [validate-registries] fail (blocked); validation error: Unknown Image registry. rule validate-registries failed at path /spec/containers/0/image/
3m         Warning   PolicyViolation   clusterpolicy/restrict-image-registries   Pod default/nginx-public: [validate-registries] fail (blocked); validation error: Unknown Image registry. rule validate-registries failed at path /spec/containers/0/image/
```

> 참고: 출력은 다를 수 있습니다.

이제 실습에서 사용한 `default` 네임스페이스에 대한 정책 보고서를 자세히 살펴보겠습니다:

```bash
$ kubectl get policyreports
NAME                                           PASS   FAIL   WARN   ERROR   SKIP   AGE
default       cpol-baseline-policy             2      0      0      0       0      19m
default       cpol-require-labels              2      0      0      0       0      13m
default       cpol-restrict-image-registries   1      1      0      0       0      13m
```

`restrict-image-registries` ClusterPolicy에 대해 하나의 `FAIL`과 하나의 `PASS` 보고서가 있음을 주목하세요. 이는 모든 ClusterPolicy가 `Enforce` 모드로 생성되었고, 언급했듯이 차단된 리소스는 보고되지 않기 때문입니다. 또한 정책 규칙을 위반할 수 있는 이전에 실행 중이던 리소스는 이미 제거되었습니다.

공개적으로 사용 가능한 이미지로 실행 중인 `nginx` Pod는 `restrict-image-registries` 정책을 위반하는 유일한 남은 리소스이며, 이는 보고서에 표시됩니다.

이 정책의 위반 사항을 더 자세히 살펴보려면 특정 보고서를 설명하세요. `restrict-image-registries` ClusterPolicy에 대한 검증 결과를 보려면 `cpol-restrict-image-registries` 보고서에 대해 `kubectl describe` 명령을 사용하세요:

```bash
$ kubectl describe policyreport cpol-restrict-image-registries
Name:         cpol-restrict-image-registries
Namespace:    default
Labels:       app.kubernetes.io/managed-by=kyverno
              cpol.kyverno.io/restrict-image-registries=607025
Annotations:  <none>
API Version:  wgpolicyk8s.io/v1alpha2
Kind:         PolicyReport
Metadata:
  Creation Timestamp:  2024-01-18T01:03:40Z
  Generation:          1
  Resource Version:    607320
  UID:                 7abb6c11-9610-4493-ab1e-df94360ce773
Results:
  Message:  validation error: Unknown Image registry. rule validate-registries failed at path /spec/containers/0/image/
  Policy:   restrict-image-registries
  Resources:
    API Version:  v1
    Kind:         Pod
    Name:         nginx
    Namespace:    default
    UID:          dd5e65a9-66b5-4192-89aa-a291d150807d
  Result:         fail
  Rule:           validate-registries
  Scored:         true
  Source:         kyverno
  Timestamp:
    Nanos:    0
    Seconds:  1705539793
  Message:    validation rule 'validate-registries' passed.
  Policy:     restrict-image-registries
  Resources:
    API Version:  v1
    Kind:         Pod
    Name:         nginx-ecr
    Namespace:    default
    UID:          e638aad7-7fff-4908-bbe8-581c371da6e3
  Result:         pass
  Rule:           validate-registries
  Scored:         true
  Source:         kyverno
  Timestamp:
    Nanos:    0
    Seconds:  1705539793
Summary:
  Error:  0
  Fail:   1
  Pass:   1
  Skip:   0
  Warn:   0
Events:   <none>
```

위의 출력은 `nginx` Pod 정책 검증이 `fail` 결과와 검증 오류 메시지를 받은 것을 보여줍니다. 반면에 `nginx-ecr` 정책 검증은 `pass` 결과를 받았습니다. 이러한 방식으로 보고서를 모니터링하는 것은 관리자에게 부담이 될 수 있습니다. Kyverno는 또한 이 워크샵의 범위를 벗어나는 [Policy reporter](https://kyverno.github.io/policy-reporter/core/targets/#policy-reporter-ui)를 위한 GUI 기반 도구를 지원합니다.

이 실습에서는 Kyverno로 Kubernetes PSA/PSS 구성을 보강하는 방법을 배웠습니다. Pod Security Standards (PSS)와 이러한 표준의 Kubernetes 내장 구현인 Pod Security Admission (PSA)은 pod 보안 관리를 위한 좋은 기반을 제공합니다. Kubernetes Pod Security Policies (PSP)에서 전환하는 대부분의 사용자는 PSA/PSS 기능을 사용하여 성공적으로 전환할 수 있습니다.

Kyverno는 내장된 Kubernetes pod 보안 구현을 활용하고 여러 유용한 개선 사항을 제공함으로써 PSA/PSS가 만든 사용자 경험을 향상시킵니다. Kyverno를 사용하여 pod 보안 레이블의 적절한 사용을 관리할 수 있습니다. 또한 새로운 Kyverno `validate.podSecurity` 규칙을 사용하여 추가적인 유연성과 향상된 사용자 경험으로 pod 보안 표준을 쉽게 관리할 수 있습니다. 그리고 Kyverno CLI를 사용하면 클러스터 업스트림에서 정책 평가를 자동화할 수 있습니다.