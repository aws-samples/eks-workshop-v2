---
title: Helm
sidebar_custom_props: { "module": true }
sidebar_position: 50
tmdTranslationSourceHash: '5f7ef990a504bc7200491f65c8407b7a'
---

::required-time

:::tip 시작하기 전에
이 섹션을 위한 환경을 준비합니다:

```bash timeout=600 wait=10
$ prepare-environment introduction/helm
```

:::

이 워크샵에서는 주로 Kustomize를 사용하지만, EKS 클러스터에 특정 패키지를 설치할 때 Helm을 사용하는 경우도 있습니다. 이 실습에서는 Helm에 대한 간단한 소개를 제공하며, 사전 패키징된 애플리케이션을 설치하는 방법을 시연합니다.

:::info

이 실습은 여러분의 워크로드를 위한 Helm 차트 작성을 다루지 않습니다. 이 주제에 대한 자세한 내용은 이 [가이드](https://helm.sh/docs/chart_template_guide/)를 참조하세요.

:::

[Helm](https://helm.sh)은 Kubernetes 애플리케이션을 정의, 설치 및 업그레이드하는 데 도움이 되는 Kubernetes용 패키지 매니저입니다. Helm은 차트라는 패키징 형식을 사용하며, 이는 애플리케이션을 실행하는 데 필요한 모든 Kubernetes 리소스 정의를 포함합니다. Helm은 Kubernetes 클러스터에서 애플리케이션의 배포 및 관리를 단순화합니다.

## Helm CLI

`helm` CLI 도구는 일반적으로 Kubernetes 클러스터와 함께 사용되어 애플리케이션의 배포 및 라이프사이클을 관리합니다. 이는 Kubernetes에서 애플리케이션을 패키징, 설치 및 관리하는 일관되고 반복 가능한 방법을 제공하여 다양한 환경에서 애플리케이션 배포를 자동화하고 표준화하기 쉽게 만듭니다.

CLI는 이미 웹 IDE에 설치되어 있습니다:

```bash
$ helm version
```

## Helm 차트 설치하기

Kustomize 매니페스트 대신 Helm 차트를 사용하여 샘플 애플리케이션의 UI 컴포넌트를 설치해 보겠습니다. Helm 패키지 매니저를 사용하여 차트를 설치하면 해당 차트에 대한 새로운 **릴리스**가 생성됩니다. 각 릴리스는 Helm에 의해 추적되며 다른 릴리스와 독립적으로 업그레이드, 롤백 또는 제거할 수 있습니다.

먼저 기존 UI 애플리케이션을 삭제하겠습니다:

```bash
$ kubectl delete namespace ui
```

다음으로 차트를 설치할 수 있습니다:

```bash hook=install
$ helm install ui \
  oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.2.1 \
  --create-namespace --namespace ui \
  --wait
```

이 명령을 다음과 같이 분석할 수 있습니다:

- `install` 하위 명령을 사용하여 Helm에 차트 설치를 지시합니다
- 릴리스 이름을 `ui`로 지정합니다
- 특정 버전의 [ECR Public](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui-chart)에 호스팅된 차트를 사용합니다
- `ui` 네임스페이스에 차트를 설치합니다
- 릴리스의 Pod가 준비 상태가 될 때까지 기다립니다

차트가 설치되면 EKS 클러스터의 릴리스를 나열할 수 있습니다:

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART                               APP VERSION
ui     ui         1         2024-06-11 03:58:39.862100855 +0000 UTC  deployed  retail-store-sample-ui-chart-X.X.X
```

지정한 네임스페이스에서 실행 중인 애플리케이션도 확인할 수 있습니다:

```bash
$ kubectl get pod -n ui
NAME                     READY   STATUS    RESTARTS   AGE
ui-55fbd7f494-zplwx      1/1     Running   0          119s
```

## 차트 옵션 설정하기

위의 예제에서는 [기본 구성](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/ui/chart/values.yaml)으로 차트를 설치했습니다. 종종 컴포넌트의 동작을 수정하기 위해 설치 중에 차트에 구성 **값**을 제공해야 할 수 있습니다.

설치 중에 차트에 값을 제공하는 두 가지 일반적인 방법이 있습니다:

1. YAML 파일을 생성하고 `-f` 또는 `--values` 플래그를 사용하여 Helm에 전달합니다
1. `--set` 플래그 다음에 `key=value` 쌍을 사용하여 값을 전달합니다

이러한 방법을 결합하여 UI 릴리스를 업데이트해 보겠습니다. 다음 `values.yaml` 파일을 사용하겠습니다:

```file
manifests/modules/introduction/helm/values.yaml
```

이는 Pod에 여러 사용자 정의 Kubernetes 어노테이션을 추가하고 UI 테마를 재정의합니다.

:::tip[어떤 값을 사용해야 하는지 어떻게 알 수 있나요?]

많은 Helm 차트가 레플리카 및 Pod 어노테이션과 같은 일반적인 측면을 구성하기 위한 비교적 일관된 값을 가지고 있지만, 각 Helm 차트는 고유한 구성 세트를 가질 수 있습니다. 특정 차트를 설치하고 구성할 때는 문서를 통해 사용 가능한 구성 값을 검토해야 합니다.

:::

또한 `--set` 플래그를 사용하여 추가 레플리카를 추가하겠습니다:

```bash hook=replicas
$ helm upgrade ui \
  oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.2.1 \
  --create-namespace --namespace ui \
  --set replicaCount=3 \
  --values ~/environment/eks-workshop/modules/introduction/helm/values.yaml \
  --wait
```

릴리스를 나열합니다:

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART                                APP VERSION
ui     ui         2         2024-06-11 04:13:53.862100855 +0000 UTC  deployed  retail-store-sample-ui-chart-X.X.X   X.X.X
```

**revision** 열이 **2**로 업데이트된 것을 확인할 수 있습니다. Helm이 업데이트된 구성을 별도의 리비전으로 적용했기 때문입니다. 필요한 경우 이전 구성으로 롤백할 수 있습니다.

다음과 같이 특정 릴리스의 리비전 히스토리를 볼 수 있습니다:

```bash
$ helm history ui -n ui
REVISION  UPDATED                   STATUS      CHART                               APP VERSION  DESCRIPTION
1         Tue Jun 11 03:58:39 2024  superseded  retail-store-sample-ui-chart-X.X.X  X.X.X        Install complete
2         Tue Jun 11 04:13:53 2024  deployed    retail-store-sample-ui-chart-X.X.X  X.X.X        Upgrade complete
```

변경 사항이 적용되었는지 확인하려면 `ui` 네임스페이스의 Pod를 나열합니다:

```bash
$ kubectl get pods -n ui
NAME                     READY   STATUS    RESTARTS   AGE
ui-55fbd7f494-4hz9b      1/1     Running   0          30s
ui-55fbd7f494-gkr2j      1/1     Running   0          30s
ui-55fbd7f494-zplwx      1/1     Running   0          5m
```

이제 3개의 레플리카가 실행되고 있는 것을 확인할 수 있습니다. Deployment를 검사하여 어노테이션이 적용되었는지도 확인할 수 있습니다:

```bash
$ kubectl get -o yaml deployment ui -n ui | yq '.spec.template.metadata.annotations'
my-annotation: my-value
[...]
```

## 릴리스 제거하기

CLI를 사용하여 릴리스를 제거할 수도 있습니다:

```bash
$ helm uninstall ui --namespace ui --wait
```

이렇게 하면 EKS 클러스터에서 해당 릴리스의 차트에 의해 생성된 모든 리소스가 삭제됩니다.

이제 Helm의 작동 방식을 이해했으니 [Fundamentals 모듈](/docs/fundamentals)로 진행하세요.

