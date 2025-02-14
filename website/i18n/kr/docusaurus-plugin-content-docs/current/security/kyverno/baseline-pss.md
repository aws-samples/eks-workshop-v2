---
title: "Pod 보안 표준 적용"
sidebar_position: 72
---

[Pod 보안 표준(PSS)](../pod-security-standards/) 섹션의 소개에서 논의된 바와 같이, **Privileged**, **Baseline**, **Restricted** 세 가지의 사전 정의된 정책 수준이 있습니다. Restricted PSS 구현이 권장되지만, 적절하게 구성되지 않으면 애플리케이션 수준에서 의도하지 않은 동작을 일으킬 수 있습니다. 시작하기 위해서는 컨테이너가 HostProcess, HostPath, HostPorts에 접근하거나 트래픽 스누핑을 허용하는 것과 같은 알려진 권한 상승을 방지하는 Baseline 정책을 설정하는 것이 권장됩니다. 그런 다음 이러한 특권적 접근을 제한하거나 금지하는 개별 정책을 설정할 수 있습니다.

Kyverno Baseline 정책은 단일 정책 하에서 알려진 모든 권한 상승을 제한하는 데 도움이 됩니다. 또한 정기적인 유지보수와 업데이트를 통해 최신 발견된 취약점을 정책에 통합할 수 있습니다.

특권 컨테이너는 호스트가 수행할 수 있는 거의 모든 작업을 수행할 수 있으며, 종종 CI/CD 파이프라인에서 컨테이너 이미지를 빌드하고 게시할 수 있도록 사용됩니다. 현재는 수정된 [CVE-2022-23648](https://github.com/containerd/containerd/security/advisories/GHSA-crp2-qrr5-8pq7)에서, 악의적인 행위자가 Control Groups `release_agent` 기능을 악용하여 컨테이너 호스트에서 임의의 명령을 실행함으로써 특권 컨테이너를 탈출할 수 있었습니다.

이 실습에서는 EKS 클러스터에서 특권 Pod를 실행해 보겠습니다. 다음 명령을 실행하세요:

```bash
$ kubectl run privileged-pod --image=nginx --restart=Never --privileged
pod/privileged-pod created
$ kubectl delete pod privileged-pod
pod "privileged-pod" deleted
```

이러한 상승된 특권 기능을 방지하고 이러한 권한의 무단 사용을 피하기 위해, Kyverno를 사용하여 Baseline 정책을 설정하는 것이 권장됩니다.

Pod 보안 표준의 baseline 프로파일은 Pod를 보호하기 위해 취할 수 있는 가장 기본적이고 중요한 단계들의 모음입니다. Kyverno 1.8부터는 단일 규칙을 통해 전체 프로파일을 클러스터에 할당할 수 있습니다. Baseline 프로파일이 차단하는 권한에 대해 자세히 알아보려면 [Kyverno 문서](https://kyverno.io/policies/#:~:text=Baseline%20Pod%20Security%20Standards,cluster%20through%20a%20single%20rule)를 참조하세요.

```file
manifests/modules/security/kyverno/baseline-policy/baseline-policy.yaml
```

위의 정책이 `Enforce` 모드에 있으며 특권 Pod 생성 요청을 차단할 것임을 주의하세요.

Baseline 정책을 적용해 보세요:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/baseline-policy/baseline-policy.yaml
clusterpolicy.kyverno.io/baseline-policy created
```

이제 특권 Pod를 다시 실행해 보세요:

```bash expectError=true
$ kubectl run privileged-pod --image=nginx --restart=Never --privileged
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/default/privileged-pod was blocked due to the following policies

baseline-policy:
  baseline: |
    Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": ({Allowed:false ForbiddenReason:privileged ForbiddenDetail:container "privileged-pod" must not set securityContext.privileged=true})
```

보시다시피, 클러스터에 설정된 Baseline 정책을 준수하지 않아 생성이 실패했습니다.

### 자동 생성된 정책에 대한 참고사항

Pod 보안 승인(PSA)은 Pod 수준에서 작동하지만, 실제로 Pod는 일반적으로 Deployment와 같은 Pod 컨트롤러에 의해 관리됩니다. Pod 컨트롤러 수준에서 Pod 보안 오류에 대한 표시가 없으면 문제를 해결하기가 복잡해질 수 있습니다. PSA enforce 모드는 Pod 생성을 방지하는 유일한 PSA 모드입니다. 하지만 PSA 시행은 Pod 컨트롤러 수준에서 작동하지 않습니다. 이러한 경험을 개선하기 위해 PSA `warn`과 `audit` 모드를 `enforce`와 함께 사용하는 것이 권장됩니다. 이렇게 하면 PSA는 컨트롤러 리소스가 적용된 PSS 수준에서 실패할 Pod를 생성하려 한다는 것을 표시할 것입니다.

Kubernetes와 함께 Policy-as-Code(PaC) 솔루션을 사용하면 클러스터 내에서 사용되는 모든 다른 리소스를 다루는 정책을 작성하고 유지하는 또 다른 과제가 있습니다. [Kyverno Auto-Gen Rules for Pod Controllers](https://kyverno.io/docs/writing-policies/autogen/) 기능을 사용하면 Pod 정책이 관련 Pod 컨트롤러(Deployment, DaemonSet 등) 정책을 자동으로 생성합니다. 이 Kyverno 기능은 정책의 표현적 특성을 향상시키고 관련 리소스에 대한 정책 유지 관리 노력을 줄여, 기본 Pod가 차단되는 동안 컨트롤러 리소스가 진행되지 않는 PSA 사용자 경험을 개선합니다.