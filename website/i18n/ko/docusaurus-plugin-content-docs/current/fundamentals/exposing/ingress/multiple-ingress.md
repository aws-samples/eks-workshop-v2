---
title: "다중 Ingress 패턴"
sidebar_position: 30
tmdTranslationSourceHash: '2e75c3dcc5a0600975e14bd41effa2a4'
---

동일한 EKS 클러스터에서 여러 Ingress 객체를 활용하는 것은 일반적인 방식입니다. 예를 들어, 여러 다른 워크로드를 노출하는 경우가 있습니다. 기본적으로 각 Ingress는 별도의 ALB를 생성하지만, IngressGroup 기능을 활용하여 여러 Ingress 리소스를 그룹화할 수 있습니다. 컨트롤러는 IngressGroup 내의 모든 Ingress에 대한 규칙을 자동으로 병합하고 단일 ALB로 지원합니다. 또한 Ingress에 정의된 대부분의 어노테이션은 해당 Ingress에서 정의한 경로에만 적용됩니다.

이 예제에서는 `ui` 컴포넌트와 동일한 ALB를 통해 `catalog` API를 노출하고, 경로 기반 라우팅을 활용하여 적절한 Kubernetes 서비스로 요청을 전달합니다.

먼저 `ui` 컴포넌트에 대한 새로운 Ingress를 생성합니다:

::yaml{file="manifests/modules/exposing/ingress/multiple-ingress/ingress-ui.yaml" paths="metadata.annotations,spec.rules.0"}

1. `alb.ingress.kubernetes.io/group.name` 어노테이션을 추가하여 IngressGroup을 `retail-app-group`으로 설정합니다
2. rules 섹션은 ALB가 트래픽을 라우팅하는 방법을 표현하는 데 사용됩니다. `ui` 컴포넌트의 경우 경로가 `/`로 시작하는 모든 HTTP 요청을 포트 80의 `ui`라는 Kubernetes 서비스로 라우팅합니다


그런 다음 `catalog` 컴포넌트에 대한 별도의 Ingress를 생성합니다:

::yaml{file="manifests/modules/exposing/ingress/multiple-ingress/ingress-catalog.yaml" paths="metadata.annotations,spec.rules.0"}

1. `ui` 컴포넌트와 동일한 IngressGroup을 지정하려면 annotations 섹션에서 `alb.ingress.kubernetes.io/group.name`을 `retail-app-group` 값으로 설정합니다
2. rules 섹션은 ALB가 트래픽을 라우팅하는 방법을 표현하는 데 사용됩니다. `catalog` 컴포넌트의 경우 경로가 `/catalog`로 시작하는 모든 HTTP 요청을 포트 80의 `catalog`라는 Kubernetes 서비스로 라우팅합니다

이 매니페스트를 클러스터에 적용합니다:

```bash wait=60
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/multiple-ingress
```

이제 클러스터에 `-multi`로 끝나는 두 개의 추가 Ingress 객체가 생성됩니다:

```bash
$ kubectl get ingress -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE      NAME      CLASS   HOSTS   ADDRESS                                                              PORTS   AGE
catalog-multi  catalog   alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
ui-multi       ui        alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
ui             ui        alb     *       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com                     80      4m3s
```

두 Ingress의 `ADDRESS`가 동일한 URL인 것을 확인할 수 있습니다. 이는 두 Ingress 객체가 동일한 ALB 뒤에서 함께 그룹화되었기 때문입니다.

ALB 리스너를 살펴보면 이것이 어떻게 작동하는지 확인할 수 있습니다:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-retailappgroup`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN | jq -r '.Listeners[0].ListenerArn')
$ aws elbv2 describe-rules --listener-arn $LISTENER_ARN
```

이 명령의 출력은 다음을 보여줍니다:

- 경로 접두사가 `/catalog`인 요청은 catalog 서비스의 대상 그룹으로 전송됩니다
- 그 외의 모든 것은 ui 서비스의 대상 그룹으로 전송됩니다
- 기본 백업으로 누락된 요청에 대해 404가 있습니다

AWS 콘솔에서 새로운 ALB 구성을 확인할 수도 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=retail-app-group;sort=loadBalancerName" service="ec2" label="EC2 콘솔 열기"/>

로드 밸런서의 프로비저닝이 완료될 때까지 기다리려면 다음 명령을 실행하세요:

```bash timeout=180
$ curl --head -X GET --retry 30 --retry-all-errors --retry-delay 15 --connect-timeout 30 --max-time 60 \
  -k $(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
```

브라우저에서 새로운 Ingress URL에 접속하여 웹 UI가 여전히 작동하는지 확인하세요:

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ echo "http://${ADDRESS}"
http://k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com
```

이제 catalog 서비스로 전달한 경로에 접속해 보세요:

```bash
$ ADDRESS=$(kubectl get ingress -n catalog catalog-multi -o jsonpath="{.status.loadBalancer.ingress[*].hostname}")
$ curl $ADDRESS/catalog/products | jq .
```

catalog 서비스로부터 JSON 페이로드를 받게 되며, 이는 동일한 ALB를 통해 여러 Kubernetes 서비스를 노출할 수 있음을 보여줍니다.

