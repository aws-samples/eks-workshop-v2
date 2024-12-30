---
title: Helm
sidebar_custom_props: { "module": true }
sidebar_position: 50
---

::required-time

:::tip 시작하기 전에
환경 준비를 해주세요:

```bash timeout=600 wait=10
$ prepare-environment introduction/helm
```

:::

이 워크샵에서는 주로 kustomize를 사용하겠지만, EKS 클러스터에 특정 패키지를 설치하기 위해 Helm을 사용해야 하는 상황이 있을 것입니다. 이 실습에서는 Helm에 대한 간단한 소개를 하고, 미리 패키징된 애플리케이션을 설치하는 데 어떻게 사용하는지 시연하겠습니다.

:::info

이 실습은 자체 워크로드를 위한 Helm 차트 작성은 다루지 않습니다. 이 주제에 대한 자세한 내용은 이 [가이드](https://helm.sh/docs/chart_template_guide/)를 참조하세요.

:::

[Helm](https://helm.sh/)은 Kubernetes 애플리케이션을 정의, 설치 및 업그레이드하는 데 도움이 되는 Kubernetes용 패키지 관리자입니다. 차트(Chart)라고 하는 패키징 형식을 사용하며, 이는 애플리케이션을 실행하는 데 필요한 모든 Kubernetes 리소스 정의를 포함합니다. Helm은 Kubernetes 클러스터에서 애플리케이션의 배포와 관리를 단순화합니다.

## Helm CLI

`helm` CLI 도구는 일반적으로 Kubernetes 클러스터와 함께 사용되어 애플리케이션의 배포와 수명 주기를 관리합니다. 이는 Kubernetes에서 애플리케이션을 패키징, 설치 및 관리하는 일관되고 반복 가능한 방법을 제공하여 다양한 환경에서 애플리케이션 배포를 자동화 하고 표준화 하기 쉽게 만듭니다.

`helm` CLI는 이미 IDE(Workshop IDE)에 설치되어 있습니다:

```bash
$ helm version
```

## Helm 저장소

Helm 저장소는 Helm 차트가 저장되고 관리되는 곳이며, 사용자가 차트를 쉽게 검색, 공유 및 설치할 수 있게 해줍니다. Kubernetes 클러스터에 배포할 수 있는 다양한 미리 패키징된 애플리케이션과 서비스에 쉽게 접근할 수 있도록 합니다.

[Bitnami](https://github.com/bitnami/charts) Helm 저장소는 Kubernetes에서 인기 있는 애플리케이션과 도구를 배포하기 위한 Helm 차트 모음입니다.

Bitnami 저장소를 우리의 Helm CLI에 추가해보겠습니다:

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm repo update
```

이제 저장소에서 차트를 검색할 수 있습니다. 예를 들어 `nginx` 차트를 검색해보겠습니다:

```bash
$ helm search repo nginx
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
bitnami/nginx           X.X.X           X.X.X           NGINX Open Source is a web server that can be a...
[...]
```

## Helm 차트 설치하기

위에서 찾은 Helm 차트를 사용하여 EKS 클러스터에 NGINX 서버를 설치해보겠습니다. Helm 패키지 관리자를 사용하여 차트를 설치하면 해당 차트에 대한 새로운 릴리즈가 생성됩니다. 각 릴리즈는 Helm에 의해 추적되며 다른 릴리즈와 독립적으로 업그레이드, 롤백 또는 제거될 수 있습니다.

```bash
$ echo $NGINX_CHART_VERSION
$ helm install nginx bitnami/nginx \
  --version $NGINX_CHART_VERSION \
  --namespace nginx --create-namespace --wait
```

We can break this command down as follows:

- Use the `install` sub-command to instruct Helm to install a chart
- Name the release `nginx`
- Use the chart `bitnami/nginx` with the version $NGINX_CHART_VERSION
- Install the chart in the `nginx` namespace and create that namespace first
- Wait for pods in the release to get to a ready state

Once the chart has installed we can list the releases in our EKS cluster:

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART         APP VERSION
nginx  nginx      1         2024-06-11 03:58:39.862100855 +0000 UTC  deployed  nginx-X.X.X   X.X.X
```

We can also see NGINX running in the namespace we specified:

```bash
$ kubectl get pod -n nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-55fbd7f494-zplwx   1/1     Running   0          119s
```

## Configuring chart options

In the example above we installed the NGINX chart in its default configuration. Sometimes you'll need to provide configuration **values** to charts during installation to modify the way the component behaves.

There are two common ways to provide values to charts during installation:

1. Create YAML files and pass them to Helm using the `-f` or `--values` flag
2. Pass values using the `--set` flag followed by `key=value` pairs

Let's combine these methods to update our NGINX release. We'll use this `values.yaml` file:

```file
manifests/modules/introduction/helm/values.yaml
```

This adds several custom Kubernetes labels to the NGINX pods, as well as setting some resource requests.

We'll also add additional replicas using the `--set` flag:

```bash
$ helm upgrade --install nginx bitnami/nginx \
  --version $NGINX_CHART_VERSION \
  --namespace nginx --create-namespace --wait \
  --set replicaCount=3 \
  --values ~/environment/eks-workshop/modules/introduction/helm/values.yaml
```

List the releases:

```bash
$ helm list -A
NAME   NAMESPACE  REVISION  UPDATED                                  STATUS    CHART         APP VERSION
nginx  nginx      2         2024-06-11 04:13:53.862100855 +0000 UTC  deployed  nginx-X.X.X   X.X.X
```

You'll notice that the **revision** column has updated to **2** as Helm has applied our updated configuration as a distinct revision. This would allow us to rollback to our previous configuration if necessary.

You can view the revision history of a given release like this:

```bash
$ helm history nginx -n nginx
REVISION  UPDATED                   STATUS      CHART        APP VERSION  DESCRIPTION
1         Tue Jun 11 03:58:39 2024  superseded  nginx-X.X.X  X.X.X       Install complete
2         Tue Jun 11 04:13:53 2024  deployed    nginx-X.X.X  X.X.X       Upgrade complete
```

To check that our changes have taken effect list the pods in the `nginx` namespace:

```bash
$ kubectl get pods -n nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-55fbd7f494-4hz9b   1/1     Running   0          30s
nginx-55fbd7f494-gkr2j   1/1     Running   0          30s
nginx-55fbd7f494-zplwx   1/1     Running   0          5m
```

You can see we now have 3 replicas of the NGINX pod running.

## Removing releases

We can similarly uninstall a release using the CLI:

```bash
$ helm uninstall nginx --namespace nginx --wait
```

This will delete all the resources created by the chart for that release from our EKS cluster.

Now that you understand how Helm works, proceed to the [Fundamentals module](/docs/fundamentals).