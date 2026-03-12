---
title: "트래픽 라우팅 테스트"
sidebar_position: 40
tmdTranslationSourceHash: 'b2448e7873e3d3d002a0fb5f392da6c5'
---

실제 환경에서 카나리 배포는 일부 사용자에게 기능을 출시하는 데 정기적으로 사용됩니다. 이 시나리오에서는 트래픽의 75%를 새 버전의 checkout 서비스로 인위적으로 라우팅합니다. 장바구니에 다른 객체를 담아 여러 번 체크아웃 절차를 완료하면 사용자에게 애플리케이션의 2가지 버전이 표시됩니다.

먼저 Kubernetes `exec`를 사용하여 UI Pod에서 Lattice 서비스 URL이 작동하는지 확인하겠습니다. `HTTPRoute` 리소스의 어노테이션에서 이를 가져오겠습니다:

```bash
$ export CHECKOUT_ROUTE_DNS="http://$(kubectl get httproute checkoutroute -n checkout -o json | jq -r '.metadata.annotations["application-networking.k8s.aws/lattice-assigned-domain-name"]')"
$ echo "Checkout Lattice DNS is $CHECKOUT_ROUTE_DNS"
$ POD_NAME=$(kubectl -n ui get pods -o jsonpath='{.items[0].metadata.name}')
$ kubectl exec $POD_NAME -n ui -- curl -s $CHECKOUT_ROUTE_DNS/health
{"status":"ok","info":{},"error":{},"details":{}}
```

이제 UI 컴포넌트의 `ConfigMap`을 패치하여 UI 서비스가 VPC Lattice 서비스 엔드포인트를 가리키도록 해야 합니다:

```kustomization
modules/networking/vpc-lattice/ui/configmap.yaml
ConfigMap/ui
```

이 구성 변경을 적용합니다:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/vpc-lattice/ui/ \
  | envsubst | kubectl apply -f -
```

이제 UI 컴포넌트 Pod를 재시작합니다:

```bash
$ kubectl rollout restart deployment/ui -n ui
$ kubectl rollout status deployment/ui -n ui
```

브라우저를 사용하여 애플리케이션에 액세스해 보겠습니다. `ui` 네임스페이스에 `ui-nlb`라는 이름의 `LoadBalancer` 타입 서비스가 프로비저닝되어 있으며, 이를 통해 애플리케이션의 UI에 액세스할 수 있습니다.

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}'
k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

브라우저에서 이 주소에 액세스하고 여러 번 체크아웃을 시도해보세요(장바구니에 다른 항목을 담아서):

![Example Checkout](/docs/networking/vpc-lattice/examplecheckout.webp)

이제 체크아웃이 약 75%의 시간 동안 "Lattice checkout" Pod를 사용하는 것을 확인할 수 있습니다:

![Lattice Checkout](/docs/networking/vpc-lattice/latticecheckout.webp)

