---
title: "Using EKS Pod Identity"
sidebar_position: 34
hide_table_of_contents: true
---

With Amazon EKS Auto Mode, the EKS Pod Identity Agent is already included and managed by AWS in the control plane. You can verify Pod Identity is available by checking for existing pod identity associations:

```bash
$ aws eks list-pod-identity-associations --cluster-name $EKS_CLUSTER_AUTO_NAME --namespace carts
{
    "associations": []
}
```

An IAM role, which provides the required permissions for the `carts` service to read and write to the DynamoDB table, was created when the Auto Mode cluster was set up. You can view the policy as shown below:

```bash
$ aws iam get-policy-version \
  --version-id v1 --policy-arn \
  --query 'PolicyVersion.Document' \
  arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${EKS_CLUSTER_AUTO_NAME}-carts-dynamo | jq .
{
  "Statement": [
    {
      "Action": "dynamodb:*",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:dynamodb:us-west-2:267912352941:table/eks-workshop-auto-carts",
        "arn:aws:dynamodb:us-west-2:267912352941:table/eks-workshop-auto-carts/index/*"
      ],
      "Sid": "AllAPIActionsOnCart"
    }
  ],
  "Version": "2012-10-17"
}
```

The role has also been configured with the appropriate trust relationship, which allows the EKS Service Principal to assume this role for Pod Identity. You can view it with the command below:

```bash
$ aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name ${EKS_CLUSTER_AUTO_NAME}-carts-dynamo | jq .
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

Next, we will use Amazon EKS Pod Identity feature to associate an AWS IAM role with the Kubernetes Service Account that will be used by our deployment. To create the association, run the following command:

```bash wait=30
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_AUTO_NAME}-carts-dynamo \
  --namespace carts --service-account carts | jq .
{
    "association": {
        "clusterName": "eks-workshop-auto",
        "namespace": "carts",
        "serviceAccount": "carts",
        "roleArn": "arn:aws:iam::267912352941:role/eks-workshop-auto-carts-dynamo",
        "associationArn": "arn:aws:eks:us-west-2:267912352941:podidentityassociation/eks-workshop-auto/a-yg5uoymvtfgdg5tcj",
        "associationId": "a-yg5uoymvtfgdg5tcj",
        "tags": {},
        "createdAt": "2025-10-11T01:13:27.763000+00:00",
        "modifiedAt": "2025-10-11T01:13:27.763000+00:00",
        "disableSessionTags": false
    }
}
```

All that's left is to verify that the `carts` Deployment is using the `carts` Service Account:

```bash
$ kubectl -n carts describe deployment carts | grep 'Service Account'
  Service Account:  carts
```

With the Service Account verified, let's recycle the `carts` Pods:

```bash hook=enable-pod-identity hookTimeout=430
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
```
Let's check the status of the Pods to check if they are successfully rolled out:

```bash
$ kubectl -n carts rollout status deployment/carts
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

Now, let's verify if the DynamoDB permission issue that we had encountered has been resolved for the carts application in the next section.
