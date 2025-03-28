---
title: "Install Amazon CloudWatch Observability EKS add-on"
sidebar_position: 30
---

For Kubernetes cluster components that run in pods, these write to files inside the `/var/log` directory, bypassing the default logging mechanism. We can implement pod-level logging by installing the Amazon CloudWatch EKS add-on


**Install the Amazon CloudWatch Observability EKS add-on**

First, we need to check if OpenID Connect (OIDC) provider is present for the cluster or not.
Run the command and check if you get a valid value.

```bash
$ oidc_id=$(aws eks describe-cluster --name eks-workshop --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
$ aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
D09AE1314AF7E745C940B3B6958C404E
```

If not run the following command to create an OpenID Connect (OIDC) provider, if the cluster doesn't have one already

```bash
$ eksctl utils associate-iam-oidc-provider --cluster eks-workshop --approve
```

Enter the following command to create the IAM role with the CloudWatchAgentServerPolicy policy attached, and configure the agent service account to assume that role using OIDC.

```bash
$ eksctl create iamserviceaccount \
>   --name cloudwatch-agent \
>   --namespace amazon-cloudwatch --cluster eks-workshop \
>   --role-name eksworkshop-service-account-role \
>   --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
>   --role-only \
>   --approve
2024-09-30 04:04:42 [ℹ]  1 iamserviceaccount (amazon-cloudwatch/cloudwatch-agent) was included (based on the include/exclude rules)
2024-09-30 04:04:42 [!]  serviceaccounts in Kubernetes will not be created or modified, since the option --role-only is used
2024-09-30 04:04:42 [ℹ]  1 task: { create IAM role for serviceaccount "amazon-cloudwatch/cloudwatch-agent" }
2024-09-30 04:04:42 [ℹ]  building iamserviceaccount stack "eksctl-eks-workshop-addon-iamserviceaccount-amazon-cloudwatch-cloudwatch-agent"
2024-09-30 04:04:43 [ℹ]  deploying stack "eksctl-eks-workshop-addon-iamserviceaccount-amazon-cloudwatch-cloudwatch-agent"
2024-09-30 04:04:43 [ℹ]  waiting for CloudFormation stack "eksctl-eks-workshop-addon-iamserviceaccount-amazon-cloudwatch-cloudwatch-agent"
2024-09-30 04:05:13 [ℹ]  waiting for CloudFormation stack "eksctl-eks-workshop-addon-iamserviceaccount-amazon-cloudwatch-cloudwatch-agent"
```

Install the add-on by entering the following command. Replace **111122223333** with your account ID
You check the arn by going to IAM Roles and search for **eksworkshop-service-account-role** 

<ConsoleButton url="https://console.aws.amazon.com/iam/home?#roles" service="console" label="Open IAM  console"/>

```bash
$ aws eks create-addon --addon-name amazon-cloudwatch-observability --cluster-name eks-workshop --service-account-role-arn arn:aws:iam::111122223333:role/eksworkshop-service-account-role
{
    "addon": {
        "addonName": "amazon-cloudwatch-observability",
        "clusterName": "eks-workshop",
        "status": "CREATING",
        "addonVersion": "v2.1.1-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:us-west-2:697541213674:addon/eks-workshop/amazon-cloudwatch-observability/2cc92090-9e76-5b02-7e9c-b71ed079085c",
        "createdAt": "2024-09-30T04:12:30.454000+00:00",
        "modifiedAt": "2024-09-30T04:12:30.469000+00:00",
        "serviceAccountRoleArn": "arn:aws:iam::697541213674:role/eksworkshop-service-account-role",
        "tags": {}
    }
}
```
Check if CloudWatch Observability EKS add-on is installed 
```bash
$ aws eks list-addons --cluster-name eks-workshop
{
    "addons": [
        "amazon-cloudwatch-observability",
        "coredns",
        "kube-proxy",
        "vpc-cni"
    ]
}
```


