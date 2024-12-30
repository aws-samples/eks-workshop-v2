---
title: Kustomize
sidebar_custom_props: { "module": true }
sidebar_position: 40
---

::required-time

:::tip 환경 설정 준비
이 섹션을 시작하기 전에 환경 준비를 해주세요:

```bash timeout=300 wait=10
$ prepare-environment
```

:::

Kustomize를 사용하면 선언적 "kustomization" 파일을 사용하여 Kubernetes 매니페스트 파일을 관리할 수 있습니다. Kubernetes 리소스에 대한 "base" 매니페스트를 표현하고, 구성, 커스터마이징을 사용하여 변경사항을 적용하고, 많은 리소스에 걸쳐 교차 적용되는 변경사항을 쉽게 만들 수 있습니다.

예를 들어, `checkout` Deployment에 대한 다음 매니페스트 파일을 살펴보세요:

```file
manifests/base-application/checkout/deployment.yaml
```

이 파일은 이전 [시작하기](../getting-start/) 실습에서 이미 적용되었지만, Kustomize를 사용하여 `replicas` 필드를 업데이트하여 이 컴포넌트를 수평적으로 확장하고 싶다고 가정해보겠습니다. 이 YAML 파일을 수동으로 업데이트하는 대신, Kustomize를 사용하여 `spec/replicas` 필드를 1에서 3으로 업데이트할 것입니다.

이를 위해 다음 kustomization을 적용하겠습니다.

- 첫 번째 탭은 우리가 적용할 kustomization을 보여줍니다
- 두 번째 탭은 kustomization이 적용된 후 업데이트된 `Deployment/checkout` 파일이 어떻게 보이는지 미리보기를 보여줍니다
- 마지막으로, 세 번째 탭은 변경된 내용의 차이점만 보여줍니다

```kustomization
modules/introduction/kustomize/deployment.yaml
Deployment/checkout
```

`kubectl kustomize` 명령을 사용하여 이 kustomization을 적용하는 최종 Kubernetes YAML을 생성할 수 있습니다. 이 명령은 `kubectl` CLI에 번들로 포함된 `kustomize`를 호출합니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/introduction/kustomize
```

이는 많은 YAML 파일을 생성할 것이며, 이는 Kubernetes에 직접 적용할 수 있는 최종 매니페스트를 나타냅니다. `kustomize`의 출력을 `kubectl apply`로 직접 파이핑하여 이를 시연해보겠습니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/introduction/kustomize | kubectl apply -f -
namespace/checkout unchanged
serviceaccount/checkout unchanged
configmap/checkout unchanged
service/checkout unchanged
service/checkout-redis unchanged
deployment.apps/checkout configured
deployment.apps/checkout-redis unchanged
```

여러 `checkout` 관련 리소스가 `"unchanged"`로 표시되고, `deployment.apps/checkout`이 `"configured"`로 표시된 것을 볼 수 있습니다. 이는 의도된 것입니다 — 우리는 `checkout` deployment에만 변경사항을 적용하기를 원합니다. 이전 명령을 실행하면 실제로 두 개의 파일이 적용되기 때문에 이렇게 됩니다: 위에서 본 Kustomize `deployment.yaml`과 `~/environment/eks-workshop/base-application/checkout` 폴더의 모든 파일과 일치하는 `kustomization.yaml` 파일.

`patches` 필드는 패치할 특정 파일을 지정합니다.

```file
manifests/modules/introduction/kustomize/kustomization.yaml
```

`replicas` 수가 업데이트되었는지 확인하려면 다음 명령을 실행하세요:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-585c9b45c7-c456l   1/1     Running   0          2m12s
checkout-585c9b45c7-b2rrz   1/1     Running   0          2m12s
checkout-585c9b45c7-xmx2t   1/1     Running   0          40m
```

`kubectl kustomize`와 `kubectl apply`의 조합을 사용하는 대신, `kubectl apply -k <kustomization_directory>`를 사용하여 동일한 작업을 수행할 수 있습니다 (`-f` 대신 `-k` 플래그 사용). 이 방식은 워크샵 전체에서 매니페스트 파일의 변경사항을 쉽게 적용하면서 변경사항을 명확하게 표시하는 데 사용됩니다.

시도해보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/kustomize
```

애플리케이션 매니페스트를 초기 상태로 재설정하려면 원래 매니페스트 세트를 다시 적용하면 됩니다:

```bash timeout=300 wait=30
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

일부 실습 과정에서 볼 수 있는 또 다른 패턴은 다음과 같습니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/base-application \
  | envsubst | kubectl apply -f-
```

이는 `envsubst`를 사용하여 Kubernetes 매니페스트 파일의 환경 변수 초기값(placeholder)을 특정 환경에 기반한 실제 값으로 대체합니다. 예를 들어, 일부 매니페스트에서는 `$EKS_CLUSTER_NAME`으로 EKS 클러스터 이름을 참조하거나 `$AWS_REGION`으로 AWS 리전을 참조해야 합니다.

이제 Kustomize가 어떻게 작동하는지 이해했으니, [Helm 모듈](/docs/introduction/helm)로 진행하거나 직접 [기본 모듈](/docs/fundamentals)로 이동할 수 있습니다.

Kustomize에 대해 더 자세히 알아보려면 공식 [Kubernetes 문서](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)를 참조하세요.