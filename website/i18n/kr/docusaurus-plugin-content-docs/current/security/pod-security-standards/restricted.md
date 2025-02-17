---
title: "제한된 PSS 프로파일"
sidebar_position: 63
---

마지막으로 현재 Pod 강화 모범 사례를 따르는 가장 엄격하게 제한된 정책인 Restricted 프로파일을 살펴보겠습니다. `assets` 네임스페이스에 레이블을 추가하여 Restricted PSS 프로파일에 대한 모든 PSA 모드를 활성화합니다:

```kustomization
modules/security/pss-psa/restricted-namespace/namespace.yaml
Namespace/assets
```

Kustomize를 실행하여 `assets` 네임스페이스에 레이블을 추가하는 이 변경사항을 적용합니다:

```bash timeout=180 hook=restricted-namespace
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/restricted-namespace
Warning: existing pods in namespace "assets" violate the new PodSecurity enforce level "restricted:latest"
Warning: assets-d59d88b99-flkgp: allowPrivilegeEscalation != false, runAsNonRoot != true, seccompProfile
namespace/assets configured
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets unchanged
```

Baseline 프로파일과 유사하게 assets Deployment가 Restricted 프로파일을 위반한다는 경고를 받고 있습니다.

```bash
$ kubectl -n assets delete pod --all
pod "assets-d59d88b99-flkgp" deleted
```

Pod가 재생성되지 않습니다:

```bash test=false
$ kubectl -n assets get pod
No resources found in assets namespace.
```

위의 출력은 Pod 보안 구성이 Restricted PSS 프로파일을 위반하기 때문에 PSA가 `assets` 네임스페이스에서 Pod 생성을 허용하지 않았음을 나타냅니다. 이 동작은 이전 섹션에서 보았던 것과 동일합니다.

Restricted 프로파일의 경우 실제로 프로파일을 충족하기 위해 일부 보안 구성을 사전에 잠가야 합니다. `assets` 네임스페이스에 구성된 Privileged PSS 프로파일을 준수하도록 Pod 구성에 일부 보안 제어를 추가해 보겠습니다:

```kustomization
modules/security/pss-psa/restricted-workload/deployment.yaml
Deployment/assets
```

Kustomize를 실행하여 Deployment를 재생성하는 이러한 변경사항을 적용합니다:

```bash timeout=180 hook=restricted-deploy-with-changes
$ kubectl apply -k ~/environment/eks-workshop/modules/security/pss-psa/restricted-workload
namespace/assets unchanged
serviceaccount/assets unchanged
configmap/assets unchanged
service/assets unchanged
deployment.apps/assets configured
```

이제 아래 명령을 실행하여 PSA가 위의 변경사항으로 `assets` 네임스페이스에서 Deployment와 Pod의 생성을 허용하는지 확인합니다:

```bash
$ kubectl -n assets get pod
NAME                     READY   STATUS    RESTARTS   AGE
assets-8dd6fc8c6-9kptf   1/1     Running   0          3m6s
```

위의 출력은 Pod 보안 구성이 Restricted PSS 프로파일을 준수하므로 PSA가 허용되었음을 나타냅니다.

위의 보안 권한은 Restricted PSS 프로파일에서 허용되는 제어의 포괄적인 목록이 아닙니다. 각 PSS 프로파일에서 허용/금지되는 자세한 보안 제어는 [문서](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted)를 참조하십시오.