---
title: "Pod Security Standards 적용"
sidebar_position: 72
tmdTranslationSourceHash: 6c54eef9a32b6a258bedfd070210529b
---

[Pod Security Standards (PSS)](../pod-security-standards/) 섹션의 소개에서 논의한 바와 같이, **Privileged**, **Baseline**, **Restricted** 세 가지 사전 정의된 정책 레벨이 있습니다. Restricted PSS를 구현하는 것이 권장되지만, 적절하게 구성되지 않으면 애플리케이션 레벨에서 의도하지 않은 동작을 일으킬 수 있습니다. 시작하려면 컨테이너가 HostProcess, HostPath, HostPorts에 접근하거나 트래픽 스니핑을 허용하는 것과 같이 알려진 권한 상승을 방지하는 Baseline Policy를 설정하는 것이 권장됩니다. 그런 다음 개별 정책을 설정하여 컨테이너에 대한 이러한 권한 접근을 제한하거나 허용하지 않을 수 있습니다.

Kyverno Baseline Policy는 단일 정책 하에서 알려진 모든 권한 상승을 제한하는 데 도움이 됩니다. 또한 최신 발견된 취약점을 정책에 통합하기 위한 정기적인 유지 관리 및 업데이트를 허용합니다.

권한이 있는 컨테이너는 호스트가 수행할 수 있는 거의 모든 작업을 수행할 수 있으며 종종 CI/CD 파이프라인에서 컨테이너 이미지를 빌드하고 게시하는 데 사용됩니다. 현재 수정된 [CVE-2022-23648](https://github.com/containerd/containerd/security/advisories/GHSA-crp2-qrr5-8pq7)을 통해 악의적인 행위자는 Control Groups `release_agent` 기능을 악용하여 컨테이너 호스트에서 임의의 명령을 실행함으로써 권한이 있는 컨테이너를 탈출할 수 있었습니다.

이 실습에서는 EKS 클러스터에 권한이 있는 컨테이너가 포함된 Deployment를 생성합니다. 정책이 없으면 Deployment를 자유롭게 생성하고 해당 Pod 템플릿을 패치하여 권한 접근을 추가할 수 있습니다:

```bash hook=baseline-setup
$ kubectl create deployment privileged-deploy --image=public.ecr.aws/nginx/nginx
deployment.apps/privileged-deploy created
$ kubectl patch deployment privileged-deploy --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/securityContext","value":{"privileged":true}}]'
deployment.apps/privileged-deploy patched
$ kubectl delete deployment privileged-deploy
deployment.apps "privileged-deploy" deleted
```

`kubectl patch` 명령은 JSON 패치를 사용하여 Pod 템플릿의 첫 번째 컨테이너에 `securityContext`를 추가하고 `privileged: true`로 설정합니다. 이는 컨테이너에 호스트에 대한 거의 무제한적인 접근 권한을 부여합니다. 이러한 상승된 권한 기능을 방지하고 이러한 권한의 무단 사용을 피하기 위해 Kyverno를 사용하여 Baseline Policy를 설정하는 것이 권장됩니다.

Pod Security Standards의 baseline 프로필은 Pod를 보호하기 위해 취할 수 있는 가장 근본적이고 중요한 단계의 모음입니다. Kyverno 1.8부터 단일 규칙을 통해 전체 프로필을 클러스터에 할당할 수 있습니다. Baseline Profile에서 차단되는 권한에 대해 자세히 알아보려면 [Kyverno 문서](https://kyverno.io/policies/#:~:text=Baseline%20Pod%20Security%20Standards,cluster%20through%20a%20single%20rule)를 참조하세요.

::yaml{file="manifests/modules/security/kyverno/baseline-policy/baseline-policy.yaml" paths="spec.background,spec.validationFailureAction,spec.rules.0.match,spec.rules.0.validate"}

1. `background: true`는 새 리소스뿐만 아니라 기존 리소스에도 정책을 적용합니다
2. `validationFailureAction: Enforce`는 규정을 준수하지 않는 Deployment가 생성되거나 업데이트되는 것을 차단합니다
3. `match.any.resources.kinds: [Deployment]`는 클러스터 전체의 모든 Deployment 리소스에 정책을 적용합니다
4. `allowExistingViolations: false`는 이미 위반하고 있는 Deployment에 대한 업데이트도 차단되도록 합니다
5. `validate.podSecurity`는 Deployment의 Pod 템플릿에 대해 `baseline` 레벨의 Kubernetes Pod Security Standards를 적용하며, `latest` 표준 버전을 사용합니다

계속해서 Baseline Policy를 적용하세요:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/baseline-policy/baseline-policy.yaml
clusterpolicy.kyverno.io/baseline-policy created
```

이제 권한이 있는 컨테이너로 Deployment를 생성해 보겠습니다. 먼저 Deployment를 생성한 다음 Pod 템플릿에 `privileged: true`를 추가하도록 패치합니다:

```bash
$ kubectl create deployment privileged-deploy --image=public.ecr.aws/nginx/nginx
deployment.apps/privileged-deploy created
```

이제 권한이 있는 securityContext를 추가하도록 패치해 보세요:

```bash expectError=true hook=baseline-blocked
$ kubectl patch deployment privileged-deploy --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/securityContext","value":{"privileged":true}}]'
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/default/privileged-deploy was blocked due to the following policies

baseline-policy:
  baseline: 'Validation rule ''baseline'' failed. It violates PodSecurity "baseline:latest":
    (Forbidden reason: privileged, field error list: [spec.template.spec.containers[0].securityContext.privileged
    is forbidden, forbidden values found: true])'
```

보시다시피 Pod 템플릿에 `privileged: true`를 추가하는 패치는 클러스터에 설정된 Baseline Policy를 준수하지 않기 때문에 차단됩니다.

Deployment를 정리합니다:

```bash
$ kubectl delete deployment privileged-deploy --ignore-not-found=true
deployment.apps "privileged-deploy" deleted
```

