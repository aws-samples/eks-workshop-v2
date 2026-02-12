---
title: "Using EKS Pod Identity"
sidebar_position: 34
hide_table_of_contents: true
---

To use EKS Pod Identity in your cluster, the `EKS Pod Identity Agent` addon must be installed on your EKS cluster. Let's install it using the following command:

```bash timeout=300 wait=60
$ aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent
{
    "addon": {
        "addonName": "eks-pod-identity-agent",
        "clusterName": "eks-workshop",
        "status": "CREATING",
        "addonVersion": "v1.1.0-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:us-west-2:1234567890:addon/eks-workshop/eks-pod-identity-agent/9ec6cfbd-8c9f-7ff4-fd26-640dda75bcea",
        "createdAt": "2024-01-12T22:41:01.414000+00:00",
        "modifiedAt": "2024-01-12T22:41:01.434000+00:00",
        "tags": {}
    }
}

$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent
```

Now, let's take a look at what has been created in your EKS cluster by the new addon. You can see a DaemonSet deployed in the `kube-system` namespace, which runs a Pod on each Node in our cluster.

```bash
$ kubectl -n kube-system get daemonset eks-pod-identity-agent
NAME                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
eks-pod-identity-agent    3         3         3       3            3           <none>          3d21h
$ kubectl -n kube-system get pods -l app.kubernetes.io/name=eks-pod-identity-agent
NAME                           READY   STATUS    RESTARTS   AGE
eks-pod-identity-agent-4tn28   1/1     Running   0          3d21h
eks-pod-identity-agent-hslc5   1/1     Running   0          3d21h
eks-pod-identity-agent-thvf5   1/1     Running   0          3d21h
```

An IAM role, which provides the required permissions for the `carts` service to read and write to the DynamoDB table, was created when you ran the `prepare-environment` script in the first step of this module. You can view the policy as shown below:

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

The role has also been configured with the appropriate trust relationship, which allows the EKS Service Principal to assume this role for Pod Identity. You can view it with the command below:

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

Next, we will use Amazon EKS Pod Identity feature to associate an AWS IAM role with the Kubernetes Service Account that will be used by our deployment. To create the association, run the following command:

```bash wait=30
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-carts-dynamo \
  --namespace carts --service-account carts
{
    "association": {
        "clusterName": "eks-workshop",
        "namespace": "carts",
        "serviceAccount": "carts",
        "roleArn": "arn:aws:iam::1234567890:role/eks-workshop-carts-dynamo",
        "associationArn": "arn:aws::1234567890:podidentityassociation/eks-workshop/a-abcdefghijklmnop1",
        "associationId": "a-abcdefghijklmnop1",
        "tags": {},
        "createdAt": "2024-01-09T16:16:38.163000+00:00",
        "modifiedAt": "2024-01-09T16:16:38.163000+00:00"
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
$ kubectl -n carts rollout status deployment/carts
Waiting for deployment "carts" rollout to finish: 1 old replicas are pending termination...
deployment "carts" successfully rolled out
```

Now, let's verify if the DynamoDB permission issue that we had encountered has been resolved for the carts application in the next section.
