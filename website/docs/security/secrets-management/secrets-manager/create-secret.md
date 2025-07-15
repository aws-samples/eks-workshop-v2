---
title: "Storing secrets in AWS Secrets Manager"
sidebar_position: 421
---

Let's begin by creating a secret in AWS Secrets Manager using the AWS CLI. We'll create a secret that contains JSON-encoded credentials with username and password values:

```bash
$ export SECRET_SUFFIX=$(openssl rand -hex 4)
$ export SECRET_NAME="$EKS_CLUSTER_NAME-catalog-secret-${SECRET_SUFFIX}"
$ aws secretsmanager create-secret --name "$SECRET_NAME" \
  --secret-string '{"username":"catalog", "password":"dYmNfWV4uEvTzoFu"}' --region $AWS_REGION
{
    "ARN": "arn:aws:secretsmanager:$AWS_REGION:$AWS_ACCOUNT_ID:secret:$EKS_CLUSTER_NAME/catalog-secret-ABCdef",
    "Name": "eks-workshop/static-secret",
    "VersionId": "7e0b352d-6666-4444-aaaa-cec1f1d2df1b"
}
```

You can verify that the secret was created successfully by checking either the [AWS Secrets Manager Console](https://console.aws.amazon.com/secretsmanager/listsecrets) or using the AWS CLI. Let's use the CLI to examine the secret's metadata:

```bash
$ aws secretsmanager describe-secret --secret-id "$SECRET_NAME"
{
    "ARN": "arn:aws:secretsmanager:us-west-2:1234567890:secret:eks-workshop/catalog-secret-WDD8yS",
    "Name": "eks-workshop/catalog-secret",
    "LastChangedDate": "2023-10-10T20:44:51.882000+00:00",
    "VersionIdsToStages": {
        "94d1fe43-87f5-42fb-bf28-f6b090f0ca44": [
            "AWSCURRENT"
        ]
    },
    "CreatedDate": "2023-10-10T20:44:51.439000+00:00"
}
```
