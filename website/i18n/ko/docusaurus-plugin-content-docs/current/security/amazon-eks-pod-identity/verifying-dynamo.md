---
title: "DynamoDB 액세스 검증"
sidebar_position: 35
tmdTranslationSourceHash: 4130a6ea94698da1a24cf632242194ac
---

이제 `carts` Service Account가 승인된 IAM 역할과 연결되어 `carts` Pod는 DynamoDB 테이블에 액세스할 수 있는 권한을 갖게 되었습니다. 웹 스토어에 다시 액세스하여 장바구니로 이동합니다.

```bash
$ LB_HOSTNAME=$(kubectl -n ui get service ui-nlb -o jsonpath='{.status.loadBalancer.ingress[*].hostname}{"\n"}')
$ echo "http://$LB_HOSTNAME"
http://k8s-ui-uinlb-647e781087-6717c5049aa96bd9.elb.us-west-2.amazonaws.com
```

`carts` Pod가 DynamoDB 서비스에 도달할 수 있으며 이제 장바구니에 액세스할 수 있습니다!

![Cart](/img/sample-app-screens/shopping-cart.webp)

AWS IAM 역할이 Service Account와 연결된 후, 해당 Service Account를 사용하는 새로 생성된 모든 Pod는 [EKS Pod Identity webhook](https://github.com/aws/amazon-eks-pod-identity-webhook)에 의해 가로채집니다. 이 webhook은 Amazon EKS 클러스터의 컨트롤 플레인에서 실행되며 AWS에 의해 완전히 관리됩니다. 새로운 `carts` Pod를 자세히 살펴보고 새로운 환경 변수를 확인해 보겠습니다:

```bash
$ kubectl -n carts exec deployment/carts -- env | grep AWS
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://169.254.170.23/v1/credentials
AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token
```

이러한 환경 변수에 대해 주목할 점은 다음과 같습니다:

- `AWS_DEFAULT_REGION` - 리전이 EKS 클러스터와 동일하게 자동으로 설정됩니다
- `AWS_STS_REGIONAL_ENDPOINTS` - 리전별 STS 엔드포인트가 구성되어 `us-east-1`의 글로벌 엔드포인트에 과도한 부담을 주지 않습니다
- `AWS_CONTAINER_CREDENTIALS_FULL_URI` - 이 변수는 AWS SDK에게 [HTTP credential provider](https://docs.aws.amazon.com/sdkref/latest/guide/feature-container-credentials.html)를 사용하여 자격 증명을 얻는 방법을 알려줍니다. 이는 EKS Pod Identity가 `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` 쌍과 같은 것을 통해 자격 증명을 주입할 필요가 없음을 의미하며, 대신 SDK가 EKS Pod Identity 메커니즘을 통해 임시 자격 증명을 받을 수 있습니다. 이 기능의 작동 방식에 대한 자세한 내용은 [AWS 설명서](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html)에서 확인할 수 있습니다.

애플리케이션에서 Pod Identity를 성공적으로 구성했습니다.

