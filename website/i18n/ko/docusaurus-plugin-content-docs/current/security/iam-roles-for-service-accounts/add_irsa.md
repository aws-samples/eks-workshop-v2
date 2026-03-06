---
title: "IRSA 적용"
sidebar_position: 24
hide_table_of_contents: true
tmdTranslationSourceHash: 'd6a1889dc93495b99970bbbd9307c18a'
---

클러스터에서 service account에 대한 IAM role을 사용하려면, `IAM OIDC Identity Provider`가 생성되어 클러스터와 연결되어 있어야 합니다. OIDC는 이미 프로비저닝되어 EKS 클러스터와 연결되어 있습니다:

```bash
$ aws iam list-open-id-connect-providers
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::1234567890:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/7185F12D2B62B8DA97B0ECA713F66C86"
        }
    ]
}
```

Amazon EKS 클러스터와의 연결을 검증합니다.

```bash
$ aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --query 'cluster.identity'
{
    "oidc": {
        "issuer": "https://oidc.eks.us-west-2.amazonaws.com/id/7185F12D2B62B8DA97B0ECA713F66C86"
    }
}
```

`carts` 서비스가 DynamoDB 테이블을 읽고 쓰는 데 필요한 권한을 제공하는 IAM role이 이미 생성되어 있습니다. 다음과 같이 정책을 확인할 수 있습니다:

```bash
$ aws iam get-policy-version \
  --version-id v1 --policy-arn \
  --query 'PolicyVersion.Document' \
  arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${EKS_CLUSTER_NAME}-carts-dynamo | jq .
{
  "Statement": [
    {
      "Action": "dynamodb:*",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts",
        "arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-carts/index/*"
      ],
      "Sid": "AllAPIActionsOnCart"
    }
  ],
  "Version": "2012-10-17"
}
```

이 role은 또한 적절한 신뢰 관계(trust relationship)로 구성되어 있어, EKS 클러스터와 연결된 OIDC 공급자가 subject가 carts 컴포넌트의 ServiceAccount인 경우에 한해 이 role을 assume할 수 있습니다. 다음과 같이 확인할 수 있습니다:

```bash
$ aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name ${EKS_CLUSTER_NAME}-carts-dynamo | jq .
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::1234567890:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/22E1209C76AE64F8F612F8E703E5BBD7"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-west-2.amazonaws.com/id/22E1209C76AE64F8F612F8E703E5BBD7:sub": "system:serviceaccount:carts:carts"
        }
      }
    }
  ]
}
```

이제 남은 것은 `carts` 애플리케이션과 연결된 Service Account 객체를 재구성하여 필요한 annotation을 추가하는 것입니다. 그러면 IRSA가 위의 IAM role을 사용하는 Pod에 올바른 권한을 제공할 수 있습니다.
먼저 `carts` Deployment와 연결된 SA를 확인해 보겠습니다.

```bash
$ kubectl -n carts describe deployment carts | grep 'Service Account'
  Service Account:  cart
```

이제 Service Account annotation에 사용할 IAM role의 ARN을 제공하는 `CARTS_IAM_ROLE` 값을 확인해 보겠습니다.

```bash
$ echo $CARTS_IAM_ROLE
arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
```

사용할 IAM role을 확인했으면, Kustomize를 실행하여 Service Account에 변경사항을 적용할 수 있습니다.

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/security/irsa/service-account \
  | envsubst | kubectl apply -f-
```

이렇게 하면 다음과 같이 service account가 수정됩니다:

```kustomization
modules/security/irsa/service-account/carts-serviceAccount.yaml
ServiceAccount/carts
```

Service Account가 annotation되었는지 확인합니다.

```bash
$ kubectl describe sa carts -n carts | grep Annotations
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
```

ServiceAccount가 업데이트되었으므로 이제 carts Pod를 재시작하여 변경사항을 적용하면 됩니다:

```bash
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

