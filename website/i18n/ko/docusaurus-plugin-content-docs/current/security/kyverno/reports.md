---
title: "리포트 & 감사"
sidebar_position: 74
tmdTranslationSourceHash: db98a354c23b018a8031ee4bd6e8843d
---

Kyverno는 Kubernetes Policy Working Group에서 정의한 오픈 형식을 사용하는 [Policy Reporting](https://kyverno.io/docs/policy-reports/) 도구를 포함하고 있습니다. 이러한 리포트는 클러스터에 사용자 정의 리소스로 배포됩니다. Kyverno는 클러스터에서 _CREATE_, _UPDATE_, _DELETE_와 같은 admission 작업이 수행될 때 이러한 리포트를 생성합니다. 리포트는 기존 리소스에 대한 정책을 검증하는 백그라운드 스캔의 결과로도 생성됩니다.

이 워크숍 전반에 걸쳐 특정 규칙을 가진 여러 정책을 생성했습니다. 리소스가 정책 정의에 따라 하나 이상의 규칙과 일치하고 이를 위반하는 경우, 각 위반에 대해 리포트에 항목이 생성됩니다. 이는 동일한 리소스가 여러 규칙과 일치하고 위반하는 경우 여러 항목이 생성될 수 있음을 의미합니다. 리소스가 삭제되면 해당 항목은 리포트에서 제거됩니다. 즉, Kyverno 리포트는 항상 클러스터의 현재 상태를 나타내며 과거 정보를 기록하지 않습니다.

앞서 논의한 바와 같이, Kyverno에는 두 가지 유형의 `validationFailureAction`이 있습니다:

1. `Audit` 모드: 리소스 생성을 허용하고 Policy Report에 작업을 보고합니다.
2. `Enforce` 모드: 리소스 생성을 거부하지만 Policy Report에 항목을 추가하지 않습니다.

예를 들어, `Audit` 모드의 정책에 모든 Deployment가 Pod 템플릿에 `CostCenter` 레이블을 설정하도록 요구하는 단일 규칙이 포함되어 있고, 해당 레이블 없이 Deployment가 생성되는 경우, Kyverno는 Deployment의 생성을 허용하지만 규칙 위반으로 인해 Policy Report에 `FAIL` 결과로 기록합니다. 이 동일한 정책이 `Enforce` 모드로 구성된 경우, Kyverno는 즉시 Deployment 생성을 차단하며 이는 Policy Report에 항목을 생성하지 않습니다. 그러나 Deployment가 규칙을 준수하여 생성되면 리포트에 `PASS`로 보고됩니다. 차단된 작업은 작업이 요청된 네임스페이스의 Kubernetes 이벤트에서 확인할 수 있습니다.

지금까지 이 워크숍에서 생성한 정책에 대한 클러스터의 규정 준수 상태를 생성된 Policy Report를 검토하여 살펴보겠습니다.

```bash hook=reports
$ kubectl get policyreports -A
NAMESPACE     NAME                                   KIND         NAME                            PASS   FAIL   WARN   ERROR   SKIP   AGE
carts         50358693-2468-4b73-8873-c6239b90876c   Deployment   carts-dynamodb                  1      2      0      0       0      23m
carts         b0356ab5-e6a5-4326-a931-0e8d1a9f7f94   Deployment   carts                           3      0      0      0       1      23m
catalog       d6c40501-8f34-4398-97a6-27ab1050ef93   Deployment   catalog                         2      1      0      0       0      23m
checkout      3f896219-057e-40c0-bf99-c6ad4a57350b   Deployment   checkout                        2      1      0      0       0      23m
checkout      4df6b9d4-b87f-4a83-bbc3-985227280d2a   Deployment   checkout-redis                  2      1      0      0       0      23m
default       b71aba03-a65c-4ee2-baa1-0fc35b3a68ab   Deployment   nginx-public                    3      1      0      0       0      94s
default       f9802e1a-d2ee-4ee6-a9e2-c6d6f9fc7dab   Deployment   nginx-ecr                       4      0      0      0       0      14s
kube-system   ad06d729-02ec-4423-a534-fed4f1291516   Deployment   metrics-server                  1      2      0      0       0      23m
kube-system   de7f93d3-b4e5-42db-99c0-21b41559f9e3   Deployment   coredns                         1      2      0      0       0      23m
kyverno       1cfa691f-f809-4d5e-95d1-0a2367a834b0   Deployment   kyverno-reports-controller      1      2      0      0       0      23m
kyverno       94f688ff-b3de-400d-b7b5-6a17ccfe0dbd   Deployment   kyverno-admission-controller    1      2      0      0       0      23m
kyverno       adbaf20a-359b-4828-9a38-b0a30bd54d84   Deployment   kyverno-cleanup-controller      1      2      0      0       0      23m
kyverno       dd887a98-1d6f-48f6-a114-ab49eccdaa38   Deployment   kyverno-background-controller   1      2      0      0       0      23m
orders        40ed7842-7592-48b3-8998-eff2b16a898f   Deployment   orders                          2      1      0      0       0      23m
ui            590ae540-0bcc-4caa-8154-f7907fb31ff1   Deployment   ui                              3      0      0      0       0      23m
```

> 참고: 출력은 다를 수 있습니다. 리포트는 모든 네임스페이스의 Deployment에 대해 생성됩니다.

Kyverno 1.13+에서는 정책 리포트가 정책별이 아닌 리소스별로 범위가 지정됩니다. 각 리포트는 리소스의 UID로 이름이 지정되며 해당 리소스를 평가한 모든 정책에 걸쳐 집계된 합격/불합격 수를 보여줍니다. 우리의 정책이 Deployment를 대상으로 하기 때문에 리포트는 Deployment 리소스로 범위가 지정됩니다. 리포트가 `PASS`, `FAIL`, `WARN`, `ERROR`, `SKIP`을 사용하여 리소스의 상태를 표시하는 것을 볼 수 있습니다.

앞서 언급했듯이 차단된 작업은 네임스페이스 이벤트에 기록됩니다. 다음 명령을 사용하여 이를 살펴보겠습니다:

```bash
$ kubectl get events | grep block
9m11s       Warning   PolicyViolation     clusterpolicy/baseline-policy             Deployment default/privileged-deploy: [baseline] fail (blocked); Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": (Forbidden reason: privileged, field error list: [spec.template.spec.containers[0].securityContext.privileged is forbidden, forbidden values found: true])
18m         Warning   PolicyViolation     clusterpolicy/require-labels              Deployment ui/ui: [check-team] fail (blocked); validation error: Label 'CostCenter' is required on the Deployment pod template. rule check-team failed at path /spec/template/metadata/labels/CostCenter/
2m8s        Warning   PolicyViolation     clusterpolicy/restrict-image-registries   Deployment default/nginx-blocked: [validate-registries] fail (blocked); validation error: Unknown Image registry. rule validate-registries failed at path /spec/template/spec/containers/0/image/
```

> 참고: 출력은 다를 수 있습니다.

각 이벤트는 이 실습 초반의 정책 위반에 해당합니다:
- `baseline-policy`는 `privileged: true`를 추가하기 위해 패치했을 때 `privileged-deploy` Deployment를 차단했습니다
- `require-labels`는 Pod 템플릿에 `CostCenter` 레이블이 없어서 `ui` Deployment 롤아웃 재시작을 차단했습니다
- `restrict-image-registries`는 이미지가 신뢰할 수 없는 레지스트리에서 왔기 때문에 `nginx-blocked`를 차단했습니다

이러한 이벤트는 클러스터 전체에 걸친 강제 조치의 실시간 감사 추적을 제공합니다.

이제 실습에서 사용된 `default` 네임스페이스의 Policy Report를 자세히 살펴보겠습니다:

```bash
$ kubectl get policyreports
NAME                                   KIND         NAME           PASS   FAIL   WARN   ERROR   SKIP   AGE
b71aba03-a65c-4ee2-baa1-0fc35b3a68ab   Deployment   nginx-public   3      1      0      0       0      3m39s
f9802e1a-d2ee-4ee6-a9e2-c6d6f9fc7dab   Deployment   nginx-ecr      4      0      0      0       0      2m19s
```

`nginx-public` Deployment에 1개의 `FAIL`이 있고 `nginx-ecr` Deployment에는 모든 것이 통과되어 있습니다. 이는 모든 ClusterPolicy가 `Enforce` 모드로 생성되었기 때문입니다. 차단된 리소스는 보고되지 않으며, 승인된 후 백그라운드 스캐너에 의해 평가된 리소스만 보고됩니다. 공개적으로 사용 가능한 이미지로 실행 중인 상태로 남겨둔 `nginx-public` Deployment는 `restrict-image-registries` 정책을 위반하는 유일한 나머지 리소스입니다.

`nginx-public` Deployment의 위반 사항을 더 자세히 검토하려면 해당 리포트를 describe하십시오. 리포트는 UID로 이름이 지정되므로 `kubectl get policyreports`를 사용하여 `nginx-public` Deployment의 리포트 이름을 찾은 다음 describe하십시오:

```bash
$ kubectl describe policyreport $(kubectl get policyreports -o json | jq -r '.items[] | select(.scope.name=="nginx-public") | .metadata.name')
Name:         a9b8c7d6-e5f4-3210-fedc-ba9876543210
Namespace:    default
Labels:       app.kubernetes.io/managed-by=kyverno
Annotations:  <none>
API Version:  wgpolicyk8s.io/v1alpha2
Kind:         PolicyReport
Scope:
  API Version:  apps/v1
  Kind:         Deployment
  Name:         nginx-public
  Namespace:    default
Results:
  Message:  validation error: Unknown Image registry. rule validate-registries failed at path /spec/template/spec/containers/0/image/
  Policy:   restrict-image-registries
  Result:   fail
  Rule:     validate-registries
  Scored:   true
  Source:   kyverno
  ...
Summary:
  Error:  0
  Fail:   1
  Pass:   3
  Skip:   0
  Warn:   0
Events:   <none>
```

리포트는 검증 오류 메시지와 함께 `restrict-image-registries`에 대한 `nginx-public` Deployment의 `fail` 결과를 보여줍니다. `nginx-ecr` Deployment에는 모두 통과된 자체 별도 리포트가 있습니다. 이러한 방식으로 리포트를 모니터링하는 것은 관리자에게 부담이 될 수 있습니다. Kyverno는 이 워크숍의 범위를 벗어나지만 [Policy reporter](https://kyverno.github.io/policy-reporter/core/targets/#policy-reporter-ui)에 대한 GUI 기반 도구도 지원합니다.

이 실습에서는 Kyverno를 사용하여 Kubernetes PSA/PSS 구성을 보강하는 방법을 배웠습니다. Pod Security Standards(PSS)와 이러한 표준의 인트리 Kubernetes 구현인 Pod Security Admission(PSA)은 Pod 보안을 관리하기 위한 좋은 구성 요소를 제공합니다. Kubernetes Pod Security Policies(PSP)에서 전환하는 대부분의 사용자는 PSA/PSS 기능을 사용하여 성공할 수 있어야 합니다.

Kyverno는 인트리 Kubernetes Pod 보안 구현을 활용하고 여러 유용한 향상 기능을 제공하여 PSA/PSS가 생성한 사용자 경험을 개선합니다. Kyverno를 사용하여 Pod 보안 레이블의 적절한 사용을 관리할 수 있습니다. 또한 새로운 Kyverno `validate.podSecurity` 규칙을 사용하여 추가 유연성과 향상된 사용자 경험으로 Pod 보안 표준을 쉽게 관리할 수 있습니다. 그리고 Kyverno CLI를 사용하면 클러스터 업스트림에서 정책 평가를 자동화할 수 있습니다.

