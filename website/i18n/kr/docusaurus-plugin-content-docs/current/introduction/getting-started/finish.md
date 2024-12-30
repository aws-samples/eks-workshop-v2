---
title: 기타 컴포넌트
sidebar_position: 50
---

이 실습에서는 Kustomize의 기능을 활용하여 나머지 샘플 애플리케이션을 효율적으로 배포할 것입니다. 다음 `kustomization` 파일은 다른 `kustomization`을 참조하고 여러 컴포넌트를 함께 배포하는 방법을 보여줍니다:

```file
manifests/base-application/kustomization.yaml
```

:::tip
Notice that the catalog API is in this kustomization, didn't we already deploy it?

Because Kubernetes uses a declarative mechanism we can apply the manifests for the catalog API again and expect that because all of the resources are already created Kubernetes will take no action.
:::

Apply this kustomization to our cluster to deploy the rest of the components:

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

After this is complete we can use `kubectl wait` to make sure all the components have started before we proceed:

```bash timeout=200
$ kubectl wait --for=condition=Ready --timeout=180s pods \
  -l app.kubernetes.io/created-by=eks-workshop -A
```

We'll now have a Namespace for each of our application components:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME       STATUS   AGE
assets     Active   62s
carts      Active   62s
catalog    Active   7m17s
checkout   Active   62s
orders     Active   62s
other      Active   62s
rabbitmq   Active   62s
ui         Active   62s
```

We can also see all of the Deployments created for the components:

```bash
$ kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME             READY   UP-TO-DATE   AVAILABLE   AGE
assets      assets           1/1     1            1           90s
carts       carts            1/1     1            1           90s
carts       carts-dynamodb   1/1     1            1           90s
catalog     catalog          1/1     1            1           7m46s
checkout    checkout         1/1     1            1           90s
checkout    checkout-redis   1/1     1            1           90s
orders      orders           1/1     1            1           90s
orders      orders-mysql     1/1     1            1           90s
ui          ui               1/1     1            1           90s
```

The sample application is now deployed and ready to provide a foundation for us to use in the rest of the labs in this workshop!

:::tip
If you want to understand more about Kustomize take a look at the [optional module](../kustomize/index.md) provided in this workshop.
:::