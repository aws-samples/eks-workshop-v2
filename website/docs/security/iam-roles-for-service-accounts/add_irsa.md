---
title: "Applying IRSA"
sidebar_position: 40
hide_table_of_contents: true
---
 
To use IAM roles for service accounts in your cluster, an `IAM OIDC Identity Provider` must be created and associated with a cluster. An OIDC has already been provisioned and associated with your EKS cluster:

Go to the Identity Providers in IAM Console:

https://console.aws.amazon.com/iamv2/home#/identity_providers

You will see an OIDC provider has created for your EKS cluster:

![IAM OIDC Provider](./assets/oidc.png)

Another option is to use AWS CLI to verify the `IAM OIDC Identity Provider`.

```bash
$ aws iam list-open-id-connect-providers

{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::012345678901:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/7185F12D2B62B8DA97B0ECA713F66C86"
        }
    ]
}
```

And validate its association with our Amazon EKS cluster.

```bash
$ aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --query 'cluster.identity'

{
    "oidc": {
        "issuer": "https://oidc.eks.us-west-2.amazonaws.com/id/7185F12D2B62B8DA97B0ECA713F66C86"
    }
}
```


A IAM role which provides the required permissions for the `carts` service to read and write to DynamoDB table has been created for you. You can view the policy like so:

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

The role has also been configured with the appropriate trust relationship which allows the OIDC provider associated with our EKS cluster to assume this role as long as the subject is the ServiceAccount for the carts component. You can view it like so:

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

All thats left is to re-configure the Service Account object associated with the `carts` application adding the required annotation to it, so IRSA can provide the correct authorization for Pods using the IAM Role above. 
Let's validate the SA associated with the `carts` Deployment.

```bash
$ kubectl -n carts describe deployment carts | grep 'Service Account'
  Service Account:  cart
```

Now lets check the value of `CARTS_IAM_ROLE` which will provide the ARN of the IAM Role for the Service Account annotation. Then run Kustomize to apply this change:

```bash
$ echo $CARTS_IAM_ROLE
arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
$ kubectl apply -k /workspace/modules/security/irsa/service-account
```


```kustomization
security/irsa/service-account/carts-serviceAccount.yaml
ServiceAccount/carts
```

Validate if the Service Account was annotated.

```bash
$ kubectl describe sa carts -n carts | grep Annotations
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo
```

With the ServiceAccount updated now we just need to recycle the carts Pod so it picks it up:

```bash
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts
```
