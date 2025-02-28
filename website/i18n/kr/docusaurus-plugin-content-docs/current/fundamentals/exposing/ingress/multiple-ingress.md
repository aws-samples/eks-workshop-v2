---
title: "다중 Ingress 패턴"
sidebar_position: 30
---
동일한 EKS 클러스터에서 여러 개의 Ingress 객체를 활용하는 것이 일반적입니다. 예를 들어 여러 다른 워크로드를 노출하는 경우입니다. 기본적으로 각 Ingress는 별도의 ALB 생성을 초래하지만, IngressGroup 기능을 활용하여 여러 Ingress 리소스를 그룹화할 수 있습니다. 컨트롤러는 IngressGroup 내의 모든 Ingress에 대한 Ingress 규칙을 자동으로 병합하고 단일 ALB로 지원합니다. 또한, Ingress에 정의된 대부분의 어노테이션은 해당 Ingress에 의해 정의된 경로에만 적용됩니다.

이 예제에서는 경로 기반 라우팅을 활용하여 요청을 적절한 쿠버네티스 서비스로 전달하면서, `ui` 컴포넌트와 동일한 ALB를 통해 catalog API를 노출할 것입니다. 먼저 `catalog` API에 아직 접근할 수 없는지 확인해보겠습니다:

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
$ curl $ADDRESS/catalogue
```

첫 번째로 할 일은 `ui` 컴포넌트의 Ingress를 `alb.ingress.kubernetes.io/group.name` 어노테이션을 추가하여 다시 생성하는 것입니다:

```file
manifests/modules/exposing/ingress/multiple-ingress/ingress-ui.yaml
```

이제, 동일한 `group.name`을 활용하는 `catalog` 컴포넌트에 대한 별도의 Ingress를 생성해보겠습니다:

```file
manifests/modules/exposing/ingress/multiple-ingress/ingress-catalog.yaml
```

이 ingress는 `/catalogue`로 시작하는 요청을 `catalog` 컴포넌트로 라우팅하도록 규칙을 구성합니다.

이러한 매니페스트를 클러스터에 적용합니다:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/multiple-ingress
```

이제 클러스터에 두 개의 별도 Ingress 객체가 있게 됩니다:

```bash
$ kubectl get ingress -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME      CLASS   HOSTS   ADDRESS                                                              PORTS   AGE
catalog     catalog   alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
ui          ui        alb     *       k8s-retailappgroup-2c24c1c4bc-17962260.us-west-2.elb.amazonaws.com   80      2m21s
```

두 Ingress의 `ADDRESS`가 동일한 URL인 것을 주목하세요. 이는 두 Ingress 객체가 동일한 ALB 뒤에 그룹화되어 있기 때문입니다.

ALB 리스너를 살펴보면 이것이 어떻게 작동하는지 알 수 있습니다:

```bash
$ ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-retailappgroup`) == `true`].LoadBalancerArn' | jq -r '.[0]')
$ LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN | jq -r '.Listeners[0].ListenerArn')
$ aws elbv2 describe-rules --listener-arn $LISTENER_ARN
```

이 명령의 출력은 다음을 보여줍니다:

- `/catalogue` 경로 접두사가 있는 요청은 catalog 서비스의 대상 그룹으로 전송됩니다
- 나머지는 모두 `ui` 서비스의 대상 그룹으로 전송됩니다
- 기본 백업으로 누락된 요청에 대해 `404`가 있습니다

AWS 콘솔에서 새로운 ALB 구성을 확인할 수도 있습니다:

<ConsoleButton url="https://console.aws.amazon.com/ec2/home#LoadBalancers:tag:ingress.k8s.aws/stack=retail-app-group;sort=loadBalancerName" service="ec2" label="Open EC2 console"/>

로드 밸런서의 프로비저닝이 완료될 때까지 기다리려면 다음 명령을 실행할 수 있습니다:

```bash
$ wait-for-lb $(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

이전처럼 브라우저에서 새로운 Ingress URL에 접근하여 웹 UI가 여전히 작동하는지 확인해보세요:

```bash
$ kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com
```

이제 catalog 서비스로 지정한 특정 경로에 접근해보세요:

```bash
$ ADDRESS=$(kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
$ curl $ADDRESS/catalogue | jq .
```

catalog 서비스로부터 JSON 페이로드를 받게 될 것입니다. 이는 동일한 ALB를 통해 여러 쿠버네티스 서비스를 노출할 수 있었음을 보여줍니다.
