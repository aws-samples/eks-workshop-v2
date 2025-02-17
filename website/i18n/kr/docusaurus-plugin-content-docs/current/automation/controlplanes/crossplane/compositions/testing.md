---
title: "애플리케이션 테스트"
sidebar_position: 40
---

이제 Crossplane Compositions를 사용하여 DynamoDB 테이블을 프로비저닝했으니, 새 테이블과 함께 애플리케이션이 제대로 작동하는지 테스트해보겠습니다.

먼저, 업데이트된 구성을 사용하도록 파드를 재시작해야 합니다:

```bash
$ kubectl rollout restart -n carts deployment/carts
$ kubectl rollout status -n carts deployment/carts --timeout=2m
deployment "carts" successfully rolled out
```

애플리케이션에 접근하기 위해, 이전 섹션에서 사용한 것과 동일한 로드 밸런서를 사용하겠습니다. 호스트 이름을 확인해보겠습니다:

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

이 URL을 웹 브라우저에 복사하여 애플리케이션에 접근할 수 있습니다. 사용자가 실제로 사용하는 것처럼 웹 스토어의 사용자 인터페이스를 보고 사이트를 탐색할 수 있습니다.

<Browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

**Carts** 모듈이 새로 프로비저닝된 DynamoDB 테이블을 실제로 사용하고 있는지 확인하려면 다음 단계를 따르세요:

1. 웹 인터페이스에서 장바구니에 몇 가지 항목을 추가합니다.
2. 아래 스크린샷과 같이 항목들이 장바구니에 나타나는 것을 확인합니다:

![장바구니에 추가된 항목을 보여주는 스크린샷](../assets/cart-items-present.webp)

이러한 항목들이 DynamoDB 테이블에 저장되고 있는지 확인하려면 다음 명령을 실행하세요:

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-crossplane"
```

이 명령은 DynamoDB 테이블의 내용을 표시하며, 여기에는 장바구니에 추가한 항목들이 포함되어 있어야 합니다.

축하합니다! Crossplane Compositions를 사용하여 AWS 리소스를 성공적으로 생성하고 애플리케이션이 이러한 리소스와 함께 올바르게 작동하는 것을 확인했습니다. 이는 Kubernetes 클러스터에서 직접 클라우드 리소스를 관리하는 Crossplane의 강력한 기능을 보여줍니다.