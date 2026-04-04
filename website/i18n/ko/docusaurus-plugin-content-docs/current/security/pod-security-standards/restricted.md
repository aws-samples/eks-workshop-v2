---
title: "Restricted PSS 프로파일"
sidebar_position: 63
tmdTranslationSourceHash: 'b318b5d3cd34989c6d33d2a6558d0c68'
---

마지막으로 가장 엄격하게 제한된 정책인 Restricted 프로파일을 살펴보겠습니다. 이 프로파일은 현재 Pod 강화 모범 사례를 따릅니다. `pss` 네임스페이스에 레이블을 추가하여 Restricted PSS 프로파일에 대한 모든 PSA 모드를 활성화하세요:

```kustomization
modules/security/pss-psa/restricted-namespace/namespace.yaml
Namespace/pss
```

Kustomize를 실행하여 `pss` 네임스페이스에 레이블을 추가하는 변경 사항을 적용합니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/restricted-namespace
Warning: existing pods in namespace "pss" violate the new PodSecurity enforce level "restricted:latest"
Warning: pss-d59d88b99-flkgp: allowPrivilegeEscalation != false, runAsNonRoot != true, seccompProfile
namespace/pss configured
deployment.apps/pss unchanged
```

Baseline 프로파일과 유사하게 pss Deployment가 Restricted 프로파일을 위반하고 있다는 경고를 받습니다.

```bash
$ kubectl -n pss delete pod --all
pod "pss-d59d88b99-flkgp" deleted
```

Pod가 다시 생성되지 않습니다:

```bash hook=no-pods
$ kubectl -n pss get pod
No resources found in pss namespace.
```

위 출력은 Pod 보안 구성이 Restricted PSS 프로파일을 위반하기 때문에 PSA가 `pss` 네임스페이스에서 Pod 생성을 허용하지 않았음을 나타냅니다. 이 동작은 이전 섹션에서 본 것과 동일합니다.

Restricted 프로파일의 경우 실제로 프로파일을 충족하기 위해 일부 보안 구성을 사전에 잠가야 합니다. `pss` 네임스페이스에 구성된 Privileged PSS 프로파일을 준수하도록 Pod 구성에 몇 가지 보안 제어를 추가해 보겠습니다:

```kustomization
modules/security/pss-psa/restricted-workload/deployment.yaml
Deployment/pss
```

Kustomize를 실행하여 이러한 변경 사항을 적용하면 Deployment가 다시 생성됩니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/restricted-workload
namespace/pss unchanged
deployment.apps/pss configured
$ kubectl rollout status -n pss deployment/pss --timeout=60s
```

이제 아래 명령을 실행하여 PSA가 `pss` 네임스페이스에서 위 변경 사항으로 Deployment 및 Pod 생성을 허용하는지 확인합니다:

```bash
$ kubectl -n pss get pod
NAME                     READY   STATUS    RESTARTS   AGE
pss-8dd6fc8c6-9kptf      1/1     Running   0          3m6s
```

위 출력은 Pod 보안 구성이 Restricted PSS 프로파일을 준수하므로 PSA가 허용했음을 나타냅니다.

위 보안 권한은 Restricted PSS 프로파일에서 허용되는 제어의 포괄적인 목록이 아닙니다. 각 PSS 프로파일에서 허용/허용되지 않는 세부 보안 제어에 대해서는 [문서](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted)를 참조하세요.

