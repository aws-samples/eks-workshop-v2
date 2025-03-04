---
title: "DynamoDB 접근 확인"
sidebar_position: 25
---

이제 `carts` 서비스 계정이 인가된 IAM 역할로 주석 처리되어 `carts` Pod가 DynamoDB 테이블에 접근할 수 있는 권한을 가지게 되었습니다. 웹 스토어에 다시 접속하여 쇼핑 카트로 이동해보세요.

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

`carts` Pod가 DynamoDB 서비스에 접근할 수 있게 되어 쇼핑 카트를 이용할 수 있습니다!

<Browser url="http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com/cart">
<img src={require('@site/static/img/sample-app-screens/shopping-cart.webp').default}/>
</Browser>

새로운 `carts` Pod를 자세히 살펴보면서 어떤 일이 일어나고 있는지 확인해보겠습니다.

```bash
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_ROLE_ARN=arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
```

이러한 환경 변수들은 ConfigMap이나 Deployment에 직접 구성하는 방식으로 전달되지 않았습니다. 대신 IRSA가 자동으로 설정하여 AWS SDK가 AWS STS 서비스로부터 임시 자격 증명을 얻을 수 있도록 합니다.

주목할 만한 사항들은 다음과 같습니다:

- 리전이 자동으로 EKS 클러스터와 동일하게 설정됨
- STS 리전 엔드포인트가 구성되어 `us-east-1`의 글로벌 엔드포인트에 과도한 부하를 주지 않도록 함
- 역할 ARN이 이전에 Kubernetes ServiceAccount에 주석으로 사용했던 역할과 일치함

마지막으로, `AWS_WEB_IDENTITY_TOKEN_FILE` 변수는 AWS SDK에게 웹 ID 페더레이션을 사용하여 자격 증명을 얻는 방법을 알려줍니다. 이는 IRSA가 `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` 쌍과 같은 방식으로 자격 증명을 주입할 필요가 없으며, 대신 SDK가 OIDC 메커니즘을 통해 임시 자격 증명을 제공받을 수 있다는 것을 의미합니다. 이 기능이 어떻게 작동하는지에 대한 자세한 내용은 [AWS 문서](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc.html)에서 확인할 수 있습니다.