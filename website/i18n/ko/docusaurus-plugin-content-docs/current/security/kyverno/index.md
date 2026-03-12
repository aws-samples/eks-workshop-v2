---
title: "Kyverno를 이용한 정책 관리"
sidebar_position: 70
sidebar_custom_props: { "module": true }
description: "Amazon Elastic Kubernetes Service에서 Kyverno를 사용하여 정책을 코드로 적용합니다."
tmdTranslationSourceHash: "616bd6d5b4ce3fcba7d65bd048d989fb"
---

::required-time

:::tip 시작하기 전에
이 섹션을 위해 환경을 준비합니다:

```bash timeout=600 wait=30
$ prepare-environment security/kyverno
```

이는 실습 환경에 다음과 같은 변경사항을 적용합니다:

EKS 클러스터에 다음 Kubernetes 애드온을 설치합니다:

- Kyverno Policy Manager
- Kyverno Policies
- Policy Reporter

이러한 변경사항을 적용하는 Terraform은 [여기](https://github.com/aws-samples/eks-workshop-v2/tree/main/manifests/modules/security/kyverno/.workshop/terraform)에서 확인할 수 있습니다.
:::

프로덕션 환경에서 컨테이너 채택이 증가함에 따라, DevOps, 보안 및 플랫폼 팀은 거버넌스와 [정책을 코드로(Policy-as-Code, PaC)](https://aws.github.io/aws-eks-best-practices/security/docs/pods/#policy-as-code-pac) 관리하기 위한 효과적인 솔루션을 필요로 합니다. 이는 모든 팀이 보안에 관한 동일한 정보 소스를 공유하고 각자의 요구사항을 설명할 때 일관된 기본 "언어"를 사용하도록 보장합니다.

Kubernetes는 본질적으로 구축하고 오케스트레이션하기 위한 도구로 설계되었으며, 이는 기본적으로 미리 정의된 가드레일이 없다는 것을 의미합니다. 빌더에게 보안을 제어할 수 있는 방법을 제공하기 위해, Kubernetes는 버전 1.23부터 [Pod Security Admission (PSA)](https://kubernetes.io/docs/concepts/security/pod-security-admission/)를 제공합니다. PSA는 [Pod Security Standards (PSS)](https://kubernetes.io/docs/concepts/security/pod-security-standards/)에 명시된 보안 제어를 구현하는 내장 admission controller이며, Amazon Elastic Kubernetes Service (EKS)에서 기본적으로 활성화되어 있습니다.

### Kyverno란?

[Kyverno](https://kyverno.io/) (그리스어로 "통치하다"를 의미)는 Kubernetes를 위해 특별히 설계된 정책 엔진입니다. 이는 팀이 협업하고 정책을 코드로 적용할 수 있게 하는 Cloud Native Computing Foundation (CNCF) 프로젝트입니다.

Kyverno 정책 엔진은 [Dynamic Admission Controller](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)로서 Kubernetes API 서버와 통합되어, 정책이 인바운드 Kubernetes API 요청을 **변경(mutate)**하고 **검증(validate)**할 수 있도록 합니다. 이는 데이터가 영속화되고 클러스터에 적용되기 전에 정의된 규칙을 준수하도록 보장합니다.

Kyverno는 YAML로 작성된 선언적 Kubernetes 리소스를 사용하므로 새로운 정책 언어를 배울 필요가 없습니다. 결과는 Kubernetes 리소스 및 이벤트로 제공됩니다.

Kyverno 정책은 리소스 구성을 **검증**, **변경**, **생성**하고, 이미지 서명 및 증명을 **검증**하는 데 사용될 수 있어, 포괄적인 소프트웨어 공급망 보안 표준 적용에 필요한 모든 구성 요소를 제공합니다.

### Kyverno 작동 방식

Kyverno는 Kubernetes 클러스터에서 Dynamic Admission Controller로 작동합니다. Kubernetes API 서버로부터 validating 및 mutating admission webhook HTTP 콜백을 수신하고, 일치하는 정책을 적용하여 admission 정책을 적용하거나 요청을 거부하는 결과를 반환합니다. 또한 요청을 감사하고 적용 전에 환경의 보안 태세를 모니터링하는 데 사용할 수 있습니다.

아래 다이어그램은 Kyverno의 높은 수준의 논리적 아키텍처를 보여줍니다:

![KyvernoArchitecture](/docs/security/kyverno/ky-arch.webp)

두 가지 주요 구성 요소는 Webhook Server와 Webhook Controller입니다. **Webhook Server**는 Kubernetes API 서버로부터 들어오는 AdmissionReview 요청을 처리하고 이를 Engine으로 보내 처리합니다. **Webhook Controller**에 의해 동적으로 구성되며, 설치된 정책을 모니터링하고 해당 정책과 일치하는 리소스만 요청하도록 웹훅을 수정합니다.

---

실습을 진행하기 전에 `prepare-environment` 스크립트로 프로비저닝된 Kyverno 리소스를 검증합니다:

```bash
$ kubectl -n kyverno get all
NAME                                                 READY   STATUS    RESTARTS   AGE
pod/kyverno-admission-controller-8648694c5-hv8vb     1/1     Running   0          97s
pod/kyverno-background-controller-6fbcb79d89-kt7w9   1/1     Running   0          97s
pod/kyverno-cleanup-controller-549855c6d8-2jjtn      1/1     Running   0          96s
pod/kyverno-reports-controller-668c67d758-4s57g      1/1     Running   0          96s

NAME                                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/kyverno-background-controller-metrics   ClusterIP   172.16.74.233    <none>        8000/TCP   98s
service/kyverno-cleanup-controller              ClusterIP   172.16.29.137    <none>        443/TCP    98s
service/kyverno-cleanup-controller-metrics      ClusterIP   172.16.119.134   <none>        8000/TCP   98s
service/kyverno-reports-controller-metrics      ClusterIP   172.16.42.244    <none>        8000/TCP   98s
service/kyverno-svc                             ClusterIP   172.16.151.20    <none>        443/TCP    99s
service/kyverno-svc-metrics                     ClusterIP   172.16.60.130    <none>        8000/TCP   98s

NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kyverno-admission-controller    1/1     1            1           98s
deployment.apps/kyverno-background-controller   1/1     1            1           98s
deployment.apps/kyverno-cleanup-controller      1/1     1            1           97s
deployment.apps/kyverno-reports-controller      1/1     1            1           97s

NAME                                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/kyverno-admission-controller-8648694c5     1         1         1       98s
replicaset.apps/kyverno-background-controller-6fbcb79d89   1         1         1       98s
replicaset.apps/kyverno-cleanup-controller-549855c6d8      1         1         1       97s
replicaset.apps/kyverno-reports-controller-668c67d758      1         1         1       97s
```

