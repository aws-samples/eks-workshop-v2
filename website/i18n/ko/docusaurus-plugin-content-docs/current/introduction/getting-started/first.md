---
title: 첫 번째 컴포넌트 배포하기
sidebar_position: 40
tmdTranslationSourceHash: acd143a77f6b7b3e8ff5b0f0f5984d50
---

샘플 애플리케이션은 Kustomize로 쉽게 적용할 수 있도록 구성된 Kubernetes 매니페스트 세트로 구성되어 있습니다. Kustomize는 `kubectl` CLI의 기본 기능으로도 제공되는 오픈 소스 도구입니다. 이 워크샵은 Kustomize를 사용하여 Kubernetes 매니페스트에 변경 사항을 적용하므로, YAML을 수동으로 편집할 필요 없이 매니페스트 파일의 변경 사항을 더 쉽게 이해할 수 있습니다. 이 워크샵의 다양한 모듈을 진행하면서 Kustomize로 오버레이와 패치를 점진적으로 적용할 것입니다.

샘플 애플리케이션과 이 워크샵의 모듈에 대한 YAML 매니페스트를 탐색하는 가장 쉬운 방법은 IDE의 파일 브라우저를 사용하는 것입니다:

![IDE files](/docs/introduction/getting-started/ide-initial.webp)

`eks-workshop`을 확장한 다음 `base-application` 항목을 확장하면 샘플 애플리케이션의 초기 상태를 구성하는 매니페스트를 탐색할 수 있습니다:

![IDE files base](/docs/introduction/getting-started/ide-base.webp)

구조는 **샘플 애플리케이션** 섹션에서 설명한 각 애플리케이션 컴포넌트에 대한 디렉터리로 구성되어 있습니다.

`modules` 디렉터리에는 이후 실습 과정에서 클러스터에 적용할 매니페스트 세트가 포함되어 있습니다:

![IDE files modules](/docs/introduction/getting-started/ide-modules.webp)

작업을 시작하기 전에 EKS 클러스터의 현재 Namespace를 확인해 보겠습니다:

```bash
$ kubectl get namespaces
NAME                            STATUS   AGE
default                         Active   1h
kube-node-lease                 Active   1h
kube-public                     Active   1h
kube-system                     Active   1h
```

나열된 모든 항목은 사전 설치된 시스템 컴포넌트의 Namespace입니다. [Kubernetes 레이블](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)을 사용하여 Namespace를 우리가 생성한 것만 필터링하여 이를 무시하겠습니다:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
No resources found
```

먼저 catalog 컴포넌트만 배포하겠습니다. 이 컴포넌트의 매니페스트는 `~/environment/eks-workshop/base-application/catalog`에서 찾을 수 있습니다.

```bash
$ ls ~/environment/eks-workshop/base-application/catalog
configMap.yaml
deployment.yaml
kustomization.yaml
namespace.yaml
secrets.yaml
service-mysql.yaml
service.yaml
serviceAccount.yaml
statefulset-mysql.yaml
```

이러한 매니페스트에는 catalog API의 원하는 상태를 표현하는 catalog API용 Deployment가 포함되어 있습니다:

::yaml{file="manifests/base-application/catalog/deployment.yaml" paths="spec.replicas,spec.template.metadata.labels,spec.template.spec.containers.0.image,spec.template.spec.containers.0.ports,spec.template.spec.containers.0.livenessProbe,spec.template.spec.containers.0.resources"}

1. 단일 replica 실행
2. 다른 리소스가 참조할 수 있도록 Pod에 레이블 적용
3. `public.ecr.aws/aws-containers/retail-store-sample-catalog` 컨테이너 이미지 사용
4. `http`라는 이름으로 포트 8080에서 컨테이너 노출
5. `/health` 경로에 대해 [프로브/헬스체크](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) 실행
6. 특정 양의 CPU 및 메모리를 [요청](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)하여 Kubernetes 스케줄러가 충분한 가용 리소스가 있는 노드에 배치할 수 있도록 함

매니페스트에는 다른 컴포넌트가 catalog API에 액세스하는 데 사용하는 Service도 포함되어 있습니다:

::yaml{file="manifests/base-application/catalog/service.yaml" paths="spec.ports,spec.selector"}

1. 포트 80에서 자신을 노출하고 Deployment에서 노출한 `http` 포트(포트 8080)를 대상으로 함
2. 위의 Deployment에서 표현한 것과 일치하는 레이블을 사용하여 catalog Pod를 선택

catalog 컴포넌트를 생성해 보겠습니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/base-application/catalog
namespace/catalog created
serviceaccount/catalog created
configmap/catalog created
secret/catalog-db created
service/catalog created
service/catalog-mysql created
deployment.apps/catalog created
statefulset.apps/catalog-mysql created
```

이제 새로운 Namespace가 보일 것입니다:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME      STATUS   AGE
catalog   Active   15s
```

이 네임스페이스에서 실행 중인 Pod를 살펴볼 수 있습니다:

```bash
$ kubectl get pod -n catalog
NAME                       READY   STATUS    RESTARTS      AGE
catalog-846479dcdd-fznf5   1/1     Running   2 (43s ago)   46s
catalog-mysql-0            1/1     Running   0             46s
```

catalog API용 Pod와 MySQL 데이터베이스용 Pod가 있습니다. `catalog` Pod가 `CrashLoopBackOff` 상태를 표시하는 경우, 시작하기 전에 `catalog-mysql` Pod에 연결할 수 있어야 합니다. Kubernetes는 이 조건이 충족될 때까지 계속 재시작합니다. 이 경우 [kubectl wait](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#wait)를 사용하여 특정 Pod가 Ready 상태가 될 때까지 모니터링할 수 있습니다:

```bash
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

이제 Pod가 실행 중이므로 [로그를 확인](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs)할 수 있습니다. 예를 들어 catalog API의 경우:

:::tip
명령에 '-f' 옵션을 사용하여 [kubectl logs 출력을 "팔로우"](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)할 수 있습니다. (출력 팔로우를 중지하려면 CTRL-C를 사용하세요)
:::

```bash
$ kubectl logs -n catalog deployment/catalog
```

Kubernetes를 사용하면 catalog Pod의 수를 수평으로 쉽게 확장할 수 있습니다:

```bash
$ kubectl scale -n catalog --replicas 3 deployment/catalog
deployment.apps/catalog scaled
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

우리가 적용한 매니페스트는 클러스터의 다른 컴포넌트가 연결하는 데 사용할 수 있는 각 애플리케이션 및 MySQL Pod용 Service도 생성합니다:

```bash
$ kubectl get svc -n catalog
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
catalog         ClusterIP   172.20.83.84     <none>        80/TCP     2m48s
catalog-mysql   ClusterIP   172.20.181.252   <none>        3306/TCP   2m48s
```

이러한 Service는 클러스터 내부에 있으므로 인터넷이나 VPC에서도 액세스할 수 없습니다. 하지만 [exec](https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/)를 사용하여 EKS 클러스터의 기존 Pod에 액세스하여 catalog API가 작동하는지 확인할 수 있습니다:

```bash
$ kubectl -n catalog exec -i \
  deployment/catalog -- curl catalog.catalog.svc/catalog/products | jq .
```

제품 정보가 포함된 JSON 페이로드를 받아야 합니다. 축하합니다. EKS를 사용하여 Kubernetes에 첫 번째 마이크로서비스를 배포했습니다!

