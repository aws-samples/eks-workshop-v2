---
title: Deploying our first component
sidebar_position: 40
---

샘플 애플리케이션은 Kustomize를 사용하여 쉽게 적용할 수 있도록 구성된 Kubernetes 매니페스트 세트로 구성되어 있습니다. Kustomize는 오픈 소스 도구이며 `kubectl` CLI의 기본 기능으로도 제공됩니다. 이 워크샵에서는 Kustomize를 사용하여 Kubernetes 매니페스트를 변경하므로, YAML을 수동으로 편집할 필요 없이 매니페스트 파일의 변경 사항을 쉽게 이해할 수 있습니다. 이 워크샵의 다양한 모듈을 진행하면서 Kustomize를 사용하여 오버레이와 패치를 점진적으로 적용할 것입니다.

IDE의 파일 브라우저를 사용하는 것이 이 워크샵의 샘플 애플리케이션과 모듈에 대한 YAML 매니페스트를 탐색하는 가장 쉬운 방법입니다:

![Cloud9 files](./assets/cloud9-files-initial.webp)

`eks-workshop`와 `base-application` 항목을 확장하면 샘플 애플리케이션의 초기 상태를 구성하는 매니페스트를 탐색할 수 있습니다:

![Cloud9 files base](./assets/cloud9-files-base.webp)

구조는 [셈플 어플리케이션](./about) 섹션에서 설명한 각 애플리케이션 컴포넌트의 디렉토리로 구성되어 있습니다.

`modules` 디렉토리에는 이후 실습 과정에서 클러스터에 적용할 매니페스트 세트가 포함되어 있습니다:

![Cloud9 files modules](./assets/cloud9-files-modules.webp)

먼저 EKS 클러스터의 현재 Namespace를 검사해보겠습니다:

```bash
$ kubectl get namespaces
NAME                            STATUS   AGE
default                         Active   1h
kube-node-lease                 Active   1h
kube-public                     Active   1h
kube-system                     Active   1h
```

나열된 모든 항목은 사전 설치된 시스템 컴포넌트의 Namespace입니다. [Kubernetes 레이블](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)을 사용하여 우리가 생성한 Namespace만 필터링하여 이들을 무시할 것입니다:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
No resources found
```

첫 번째로 catalog 컴포넌트를 단독으로 배포할 것입니다. 이 컴포넌트의 매니페스트는 `~/environment/eks-workshop/base-application/catalog`에서 찾을 수 있습니다.

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

These manifests include the Deployment for the catalog API:

```file
manifests/base-application/catalog/deployment.yaml
```

This Deployment expresses the desired state of the catalog API component:

- Use the `public.ecr.aws/aws-containers/retail-store-sample-catalog` container image
- Run a single replica
- Expose the container on port 8080 named `http`
- Run [probes/healthchecks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) against the `/health` path
- [Requests](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) a specific amount of CPU and memory so the Kubernetes scheduler can place it on a node with enough available resources
- Apply labels to the Pods so other resources can refer to them

The manifests also include the Service used by other components to access the catalog API:

```file
manifests/base-application/catalog/service.yaml
```

This Service:

- Selects catalog Pods using labels that match what we expressed in the Deployment above
- Exposes itself on port 80
- Targets the `http` port exposed by the Deployment, which translates to port 8080

Let's create the catalog component:

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

Now we'll see a new Namespace:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME      STATUS   AGE
catalog   Active   15s
```

We can take a look at the Pods running in this namespace:

```bash
$ kubectl get pod -n catalog
NAME                       READY   STATUS    RESTARTS      AGE
catalog-846479dcdd-fznf5   1/1     Running   2 (43s ago)   46s
catalog-mysql-0            1/1     Running   0             46s
```

Notice we have a Pod for our catalog API and another for the MySQL database. If the `catalog` Pod is showing a status of `CrashLoopBackOff`, it needs to be able to connect to the `catalog-mysql` Pod before it will start. Kubernetes will keep restarting it until this is the case. In that case, we can use [kubectl wait](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#wait) to monitor specific Pods until they are in a Ready state:

```bash
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

Now that the Pods are running we can [check their logs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs), for example the catalog API:

:::tip
You can ["follow" the kubectl logs output](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) by using the '-f' option with the command. (Use CTRL-C to stop following the output)
:::

```bash
$ kubectl logs -n catalog deployment/catalog
```

Kubernetes also allows us to easily scale the number of catalog Pods horizontally:

```bash
$ kubectl scale -n catalog --replicas 3 deployment/catalog
deployment.apps/catalog scaled
$ kubectl wait --for=condition=Ready pods --all -n catalog --timeout=180s
```

The manifests we applied also create a Service for each of our application and MySQL Pods that can be used by other components in the cluster to connect:

```bash
$ kubectl get svc -n catalog
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
catalog         ClusterIP   172.20.83.84     <none>        80/TCP     2m48s
catalog-mysql   ClusterIP   172.20.181.252   <none>        3306/TCP   2m48s
```

These Services are internal to the cluster, so we cannot access them from the Internet or even the VPC. However, we can use [exec](https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/) to access an existing Pod in the EKS cluster to check the catalog API is working:

```bash
$ kubectl -n catalog exec -it \
  deployment/catalog -- curl catalog.catalog.svc/catalogue | jq .
```

You should receive back a JSON payload with product information. Congratulations, you've just deployed your first microservice to Kubernetes with EKS!