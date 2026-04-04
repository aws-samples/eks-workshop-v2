---
title: "Baseline PSS Profile"
sidebar_position: 62
tmdTranslationSourceHash: 'f15af985f33897c78496d07dceda1259'
---

Pod가 요청할 수 있는 권한을 제한하려면 어떻게 해야 할까요? 예를 들어 이전 섹션에서 pss Pod에 제공한 `privileged` 권한은 위험할 수 있으며, 공격자가 컨테이너 외부의 호스트 리소스에 접근할 수 있게 합니다.

Baseline PSS는 알려진 권한 상승을 방지하는 최소 제한 정책입니다. `pss` 네임스페이스에 레이블을 추가하여 활성화해 보겠습니다:

```kustomization
modules/security/pss-psa/baseline-namespace/namespace.yaml
Namespace/pss
```

Kustomize를 실행하여 `pss` 네임스페이스에 레이블을 추가하는 변경사항을 적용합니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/baseline-namespace
Warning: existing pods in namespace "pss" violate the new PodSecurity enforce level "baseline:latest"
Warning: pss-64c49f848b-gmrtt: privileged
namespace/pss configured
deployment.apps/pss unchanged
```

위에서 볼 수 있듯이 `pss` Deployment의 Pod가 Baseline PSS를 위반한다는 경고를 이미 받았습니다. 이는 네임스페이스 레이블 `pod-security.kubernetes.io/warn`에 의해 제공됩니다. 이제 `pss` Deployment의 Pod를 재시작합니다:

```bash
$ kubectl -n pss delete pod --all
```

Pod가 실행 중인지 확인해 봅시다:

```bash hook=no-pods
$ kubectl -n pss get pod
No resources found in pss namespace.
```

보시다시피 Pod가 실행되지 않고 있으며, 이는 네임스페이스 레이블 `pod-security.kubernetes.io/enforce`에 의해 발생했지만, 즉시 이유를 알 수는 없습니다. PSA 모드를 독립적으로 사용하면 다른 사용자 경험을 초래하는 다른 응답이 발생합니다. enforce 모드는 해당 Pod 스펙이 구성된 PSS 프로필을 위반하는 경우 Pod가 생성되는 것을 방지합니다. 그러나 이 모드에서는 Pod를 생성하는 Deployment와 같은 비-Pod Kubernetes 객체가 클러스터에 적용되는 것을 방지하지 않습니다. 이 경우에도 내부의 Pod 스펙이 적용된 PSS 프로필을 위반하더라도 마찬가지입니다. 이 경우 Deployment는 적용되지만 Pod는 적용되지 않습니다.

아래 명령을 실행하여 Deployment 리소스를 검사하고 상태 조건을 확인합니다:

```bash
$ kubectl get deployment -n pss pss -o yaml | yq '.status'
- lastTransitionTime: "2022-11-24T04:49:56Z"
  lastUpdateTime: "2022-11-24T05:10:41Z"
  message: ReplicaSet "pss-7445d46757" has successfully progressed.
  reason: NewReplicaSetAvailable
  status: "True"
  type: Progressing
- lastTransitionTime: "2022-11-24T05:10:49Z"
  lastUpdateTime: "2022-11-24T05:10:49Z"
  message: 'pods "pss-67d5fc995b-8r9t2" is forbidden: violates PodSecurity "baseline:latest": privileged (container "pss" must not set securityContext.privileged=true)'
  reason: FailedCreate
  status: "True"
  type: ReplicaFailure
- lastTransitionTime: "2022-11-24T05:10:56Z"
  lastUpdateTime: "2022-11-24T05:10:56Z"
  message: Deployment does not have minimum availability.
  reason: MinimumReplicasUnavailable
  status: "False"
  type: Available
```

일부 시나리오에서는 성공적으로 적용된 Deployment 객체가 실패한 Pod 생성을 반영한다는 즉각적인 표시가 없습니다. 문제가 있는 Pod 스펙은 Pod를 생성하지 않습니다. `kubectl get deploy -o yaml ...`로 Deployment 리소스를 검사하면 위의 테스트에서 본 것처럼 실패한 Pod의 메시지가 `.status.conditions` 요소에서 노출됩니다.

audit 및 warn PSA 모드 모두에서 Pod 제한은 위반하는 Pod가 생성되고 시작되는 것을 방지하지 않습니다. 그러나 이러한 모드에서는 각각 API 서버 감사 로그 이벤트에 대한 감사 주석과 API 서버 클라이언트(예: kubectl)에 대한 경고가 트리거됩니다. 이는 Pod 및 Pod를 생성하는 객체에 PSS 위반이 있는 Pod 스펙이 포함된 경우 발생합니다.

이제 `privileged` 플래그를 제거하여 실행되도록 `pss` Deployment를 수정해 봅시다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/baseline-workload
namespace/pss unchanged
deployment.apps/pss configured
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```

이번에는 경고를 받지 않았으므로 Pod가 실행 중인지 확인하고, 더 이상 `root` 사용자로 실행되지 않는지 검증할 수 있습니다:

```bash
$ kubectl -n pss get pod
NAME                      READY   STATUS    RESTARTS   AGE
pss-864479dc44-d9p79      1/1     Running   0          15s

$ kubectl -n pss exec $(kubectl -n pss get pods -o name) -- whoami
appuser
```

Pod가 `privileged` 모드에서 실행되는 것을 수정했으므로 이제 Baseline 프로필에서 실행될 수 있습니다.

