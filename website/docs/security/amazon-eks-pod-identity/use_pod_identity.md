---
title: "Using EKS Pod Identity"
sidebar_position: 40
hide_table_of_contents: true
---
 
To use EKS Pod Identity in your cluster, `EKS Pod Identity Agent` addon must be installed on your EKS cluster. Its already installed as part of prepare-environment step, you can verify it using below command:

```bash
$ aws eks describe-addon --cluster-name ${EKS_CLUSTER_NAME} --addon-name eks-pod-identity-agent

{
    "addon": {
        "addonName": "eks-pod-identity-agent",
        "clusterName": "eks-workshop",
        "status": "ACTIVE",
        "addonVersion": "v1.0.0-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:us-west-2:123456789012:addon/eks-workshop/eks-pod-identity-agent/6cc61b38-f8b4-a9b3-dc86-82f9828c6ca9",
        "createdAt": "2024-01-09T15:55:35.784000+00:00",
        "modifiedAt": "2024-01-09T15:56:35.784000+00:00",
        "tags": {
          "eks_addon": "eks-pod-identity-agent"
        }
    }
}
```

An IAM role which provides the required permissions for the `carts` service to read and write to DynamoDB table has been created for you. You can view the policy like so:

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

The role has also been configured with the appropriate trust relationship which allows the EKS Auth to assume this role for Pod Identity. You can view it like so:

```bash
$ aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name ${EKS_CLUSTER_NAME}-carts-dynamo | jq .
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}
```

Next, we will use Amazon EKS Pod Identity feature to associate an AWS IAM role to the Kubernetes service account that will be used by our deployment. To create the association, run the following command:

```bash
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-carts-dynamo \
  --namespace carts --service-account carts
{
    "association": {
        "clusterName": "eks-workshop",
        "namespace": "carts",
        "serviceAccount": "carts",
        "roleArn": "arn:aws:iam::111122223333:role/eks-workshop-carts-dynamo",
        "associationArn": "arn:aws::111122223333:podidentityassociation/eks-workshop/a-abcdefghijklmnop1",
        "associationId": "a-abcdefghijklmnop1",
        "tags": {},
        "createdAt": "2024-01-09T16:16:38.163000+00:00",
        "modifiedAt": "2024-01-09T16:16:38.163000+00:00"
    }
}
```

All thats left is to verify that `carts` k8s deployment is using `cart`` service account.

```bash
$ kubectl -n carts describe deployment carts | grep 'Service Account'
  Service Account:  cart
```

With the ServiceAccount verified now we just need to recycle the `carts` pods:

```bash
$ kubectl rollout restart -n carts deployment/carts
deployment.apps/carts restarted
$ kubectl rollout status -n carts deployment/carts
```
