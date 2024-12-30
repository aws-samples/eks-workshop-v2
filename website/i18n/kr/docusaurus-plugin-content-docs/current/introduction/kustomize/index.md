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

You can generate the final Kubernetes YAML that applies this kustomization with the `kubectl kustomize` command, which invokes `kustomize` that is bundled with the `kubectl` CLI:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/introduction/kustomize
```

This will generate a lot of YAML files, which represents the final manifests you can apply directly to Kubernetes. Let's demonstrate this by piping the output from `kustomize` directly to `kubectl apply`:

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

You'll notice that a number of different `checkout`-related resources are "unchanged", with the `deployment.apps/checkout` being "configured". This is intentional — we only want to apply changes to the `checkout` deployment. This happens because running the previous command actually applied two files: the Kustomize `deployment.yaml` that we saw above, as well as the following `kustomization.yaml` file which matches all files in the `~/environment/eks-workshop/base-application/checkout` folder. The `patches` field specifies the specific file to be patched:

```file
manifests/modules/introduction/kustomize/kustomization.yaml
```

To check that the number of replicas has been updated, run the following command:

```bash
$ kubectl get pod -n checkout -l app.kubernetes.io/component=service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-585c9b45c7-c456l   1/1     Running   0          2m12s
checkout-585c9b45c7-b2rrz   1/1     Running   0          2m12s
checkout-585c9b45c7-xmx2t   1/1     Running   0          40m
```

Instead of using the combination of `kubectl kustomize` and `kubectl apply` we can instead accomplish the same thing with `kubectl apply -k <kustomization_directory>` (note the `-k` flag instead of `-f`). This approach is used through this workshop to make it easier to apply changes to manifest files, while clearly surfacing the changes to be applied.

Let's try that:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/kustomize
```

To reset the application manifests back to their initial state, you can simply apply the original set of manifests:

```bash timeout=300 wait=30
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

Another pattern you will see used in some lab exercises looks like this:

```bash
$ kubectl kustomize ~/environment/eks-workshop/base-application \
  | envsubst | kubectl apply -f-
```

This uses `envsubst` to substitute environment variable placeholders in the Kubernetes manifest files with the actual values based on your particular environment. For example in some manifests we need to reference the EKS cluster name with `$EKS_CLUSTER_NAME` or the AWS region with `$AWS_REGION`.

Now that you understand how Kustomize works, you can proceed to the [Helm module](/docs/introduction/helm) or go directly to the [Fundamentals module](/docs/fundamentals).

To learn more about Kustomize, you can refer to the official Kubernetes [documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/).