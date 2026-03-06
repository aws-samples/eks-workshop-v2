---
title: "이미지 레지스트리 제한"
sidebar_position: 73
tmdTranslationSourceHash: 'a15974d13f771db6b23e1d70452004a1'
---

EKS 클러스터에서 알 수 없는 출처의 컨테이너 이미지를 사용하는 것은 상당한 보안 위험을 초래할 수 있습니다. 특히 이러한 이미지가 CVE(Common Vulnerabilities and Exposures)에 대해 스캔되지 않은 경우 더욱 그렇습니다. 이러한 위험을 완화하고 취약점 악용 위협을 줄이기 위해서는 컨테이너 이미지가 신뢰할 수 있는 레지스트리에서 유래했는지 확인하는 것이 중요합니다. 또한 많은 조직에는 자체 호스팅 프라이빗 이미지 레지스트리의 이미지만 독점적으로 사용하도록 요구하는 보안 가이드라인이 있습니다.

이 섹션에서는 Kyverno가 클러스터에서 사용할 수 있는 이미지 레지스트리를 제한하여 안전한 컨테이너 워크로드를 실행하는 데 어떻게 도움이 되는지 살펴보겠습니다.

이전 실습에서 보았듯이 사용 가능한 모든 레지스트리의 이미지로 워크로드를 배포할 수 있습니다. 기본 레지스트리를 사용하는 샘플 Deployment를 생성하는 것부터 시작하겠습니다. 기본 레지스트리는 `docker.io`를 가리킵니다:

```bash hook=registry-setup
$ kubectl create deployment nginx-public --image=nginx
deployment.apps/nginx-public created

$ kubectl get deployment nginx-public -o jsonpath='{.spec.template.spec.containers[0].image}'
nginx
```

이 경우 퍼블릭 레지스트리에서 기본 `nginx` 이미지를 참조했습니다. 그러나 악의적인 행위자가 잠재적으로 취약한 이미지를 배포하여 EKS 클러스터에서 실행하고, 클러스터의 리소스를 악용할 가능성이 있습니다.

모범 사례를 구현하기 위해 승인되지 않은 이미지 레지스트리의 사용을 제한하고 지정된 신뢰할 수 있는 레지스트리만 사용하는 정책을 정의하겠습니다.

이 실습에서는 [Amazon ECR Public Gallery](https://public.ecr.aws/)를 신뢰할 수 있는 레지스트리로 사용하여 다른 레지스트리에서 호스팅되는 이미지를 참조하는 모든 Deployment를 차단하겠습니다. 다음은 이 사용 사례에 대한 이미지 가져오기를 제한하는 샘플 Kyverno 정책입니다:

::yaml{file="manifests/modules/security/kyverno/images/restrict-registries.yaml" paths="spec.validationFailureAction,spec.background,spec.rules.0.match,spec.rules.0.validate.allowExistingViolations,spec.rules.0.validate.pattern"}

1. `validationFailureAction: Enforce`는 비준수 Deployment의 생성 또는 업데이트를 차단합니다
2. `background: true`는 새로운 리소스뿐만 아니라 기존 리소스에도 정책을 적용합니다
3. `match.any.resources.kinds: [Deployment]`는 클러스터 전체의 모든 Deployment 리소스에 정책을 적용합니다
4. `allowExistingViolations: false`는 이미 위반하고 있는 Deployment에 대한 업데이트도 차단하여, 정책이 적용되기 전에 존재했던 비준수 Deployment가 그렇지 않으면 강제 없이 업데이트될 수 있는 격차를 닫습니다
5. `validate.pattern`은 Deployment Pod 템플릿의 모든 컨테이너 이미지가 `public.ecr.aws/*` 레지스트리에서 유래해야 한다고 강제하여, 승인되지 않은 레지스트리의 이미지를 참조하는 모든 Deployment를 차단합니다

> 참고: 이 정책은 Deployment를 대상으로 합니다. InitContainers와 Ephemeral Containers는 이 패턴에서 다루지 않습니다.

다음 명령을 사용하여 이 정책을 적용하겠습니다:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/images/restrict-registries.yaml

clusterpolicy.kyverno.io/restrict-image-registries created
```

이제 퍼블릭 레지스트리의 이미지를 사용하여 새 Deployment를 생성해 보겠습니다:

```bash expectError=true hook=registry-blocked
$ kubectl create deployment nginx-blocked --image=nginx
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/default/nginx-blocked was blocked due to the following policies

restrict-image-registries:
  validate-registries: 'validation error: Unknown Image registry. rule validate-registries
    failed at path /spec/template/spec/containers/0/image/'
```

보시다시피, 이전에 생성한 Kyverno 정책으로 인해 Deployment가 차단되었습니다.

이제 정책에서 정의한 신뢰할 수 있는 레지스트리(public.ecr.aws)에서 호스팅되는 `nginx` 이미지를 사용하여 Deployment를 생성해 보겠습니다:

```bash
$ kubectl create deployment nginx-ecr --image=public.ecr.aws/nginx/nginx
deployment.apps/nginx-ecr created
```

성공했습니다! Pod 템플릿이 신뢰할 수 있는 레지스트리의 이미지를 참조하기 때문에 Deployment가 성공적으로 생성되었습니다.

이제 퍼블릭 레지스트리의 이미지를 참조하는 Deployment를 차단하고 허용된 이미지 리포지토리로만 사용을 제한하는 방법을 확인했습니다. 추가적인 보안 모범 사례로 프라이빗 리포지토리만 허용하는 것을 고려할 수 있습니다.

> 참고: 이 작업에서 생성한 실행 중인 Deployment를 제거하지 마십시오. 다음 실습에서 사용할 것입니다.

