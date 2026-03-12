---
title: "애플리케이션 테스트"
sidebar_position: 40
tmdTranslationSourceHash: '411ce978a57e7a45fb64223d34c44059'
---

이제 Crossplane Compositions를 사용하여 DynamoDB 테이블을 프로비저닝했으므로, 새 테이블과 함께 애플리케이션이 올바르게 작동하는지 테스트해 보겠습니다.

먼저 업데이트된 구성을 사용하도록 Pod를 재시작해야 합니다:

```bash
$ kubectl rollout restart -n carts deployment/carts
$ kubectl rollout status -n carts deployment/carts --timeout=2m
deployment "carts" successfully rolled out
```

애플리케이션에 액세스하려면 이전 섹션과 동일한 로드 밸런서를 사용합니다. 호스트 이름을 조회해 보겠습니다:

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

이제 이 URL을 웹 브라우저에 복사하여 애플리케이션에 액세스할 수 있습니다. 웹 스토어의 사용자 인터페이스가 표시되어 사용자가 사이트를 탐색할 수 있습니다.

<Browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

**Carts** 모듈이 실제로 새로 프로비저닝된 DynamoDB 테이블을 사용하고 있는지 확인하려면 다음 단계를 따르세요:

1. 웹 인터페이스에서 장바구니에 몇 가지 항목을 추가합니다.
2. 아래 스크린샷과 같이 항목이 장바구니에 나타나는지 확인합니다:

<img src={require('@site/static/img/sample-app-screens/shopping-cart-items.webp').default}/>

이러한 항목이 DynamoDB 테이블에 저장되고 있는지 확인하려면 다음 명령을 실행합니다:

```bash
$ aws dynamodb scan --table-name "${EKS_CLUSTER_NAME}-carts-crossplane"
```

이 명령은 DynamoDB 테이블의 내용을 표시하며, 장바구니에 추가한 항목이 포함되어야 합니다.

축하합니다! Crossplane Compositions를 사용하여 AWS 리소스를 성공적으로 생성하고 애플리케이션이 이러한 리소스와 함께 올바르게 작동하는지 확인했습니다. 이는 Kubernetes 클러스터에서 직접 클라우드 리소스를 관리하기 위해 Crossplane을 사용하는 강력함을 보여줍니다.

