---
title: "Using EKS Pod Identity"
sidebar_position: 40
hide_table_of_contents: true
---
 
To use EKS Pod Identity in your cluster, `EKS Pod Identity Agent` addon must be installed on your EKS cluster. Lets install it using below command:

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent 
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent
```

Now we can take a look at what has been created in our EKS cluster by the addon. For example, a DaemonSet will be running a pod on each node in our cluster:

```bash
$ kubectl -n kube-system get daemonset eks-pod-identity-agent 
NAME                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
eks-pod-identity-agent    3         3         3       3            3           <none>          3d21h
```

An IAM role which provides the required permissions for the `carts` service to read and write to DynamoDB table has been created for you in the `prepare-environment` step. You can view the policy as shown below:

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

The role has also been configured with the appropriate trust relationship which allows the EKS Service Principal to assume this role for Pod Identity. You can view it like so:

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

```bash wait=30
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-carts-dynamo \
  --namespace carts --service-account carts
{
    "association": {
        "clusterName": "eks-workshop",
        "namespace": "carts",
        "serviceAccount": "carts",
        "roleArn": "arn:aws:iam::123456789000:role/eks-workshop-carts-dynamo",
        "associationArn": "arn:aws::123456789000:podidentityassociation/eks-workshop/a-abcdefghijklmnop1",
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
  Service Account:  carts
```

With the ServiceAccount verified now we just need to recycle the `carts` pods:

```bash hook=enable-pod-identity hookTimeout=430
$ kubectl -n carts rollout restart deployment/carts
deployment.apps/carts restarted
$ kubectl -n carts rollout status deployment/carts
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```
