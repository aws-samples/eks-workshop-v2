---
title: "Applying IRSA"
sidebar_position: 40
hide_table_of_contents: true
---
 
To use IAM roles for service accounts in your cluster, an `IAM OIDC Identity Provider` must be created and associated with the cluster. An OIDC has already been provisioned and associated with your EKS cluster:

Go to the Identity Providers in IAM Console:

https://console.aws.amazon.com/iamv2/home#/identity_providers

You will see an OIDC provider has created for your EKS cluster:

![IAM OIDC Provider](./assets/oidc.png)

A IAM role which provides the required permissions for the carts service to read and write to DynamoDB table has been created for you. You can view the policy like so:

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
        "arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-cluster-carts",
        "arn:aws:dynamodb:us-west-2:1234567890:table/eks-workshop-cluster-carts/index/*"
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

All thats left to us is to re-configure the ServiceAccount object used by the carts service to give it with the required annotation so that IRSA provides the correct Pods with the IAM role above. It gets the name from an environment variable we've set for you called `CARTS_IAM_ROLE`.

```kustomization
security/irsa/service-account/carts-serviceAccount.yaml
ServiceAccount/carts
```

Lets check the value of `CARTS_IAM_ROLE` then run Kustomize to apply this change:

```bash
$ echo $CARTS_IAM_ROLE
arn:aws:iam::1234567890:role/eks-workshop-cluster-carts-dynamo
$ kubectl apply -k /workspace/modules/security/irsa/service-account
```

With the ServiceAccount updated now we just need to recycle the carts Pod so it picks it up:

```bash
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts
```