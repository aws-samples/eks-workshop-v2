---
title: Enabling Fargate
sidebar_position: 10
---

Before you schedule Pods on Fargate in your cluster, you must define at least one Fargate profile that specifies which Pods use Fargate when launched.

As an administrator, you can use a Fargate profile to declare which Pods run on Fargate. You can do this through the profile’s selectors. You can add up to five selectors to each profile. Each selector contains a namespace and optional labels. You must define a namespace for every selector. The label field consists of multiple optional key-value pairs. Pods that match a selector are scheduled on Fargate. Pods are matched using a namespace and the labels that are specified in the selector. If a namespace selector is defined without labels, Amazon EKS attempts to schedule all the Pods that run in that namespace onto Fargate using the profile. If a to-be-scheduled Pod matches any of the selectors in the Fargate profile, then that Pod is scheduled on Fargate.

If a Pod matches multiple Fargate profiles, you can specify which profile a Pod uses by adding the following Kubernetes label to the Pod specification: `eks.amazonaws.com/fargate-profile: my-fargate-profile`. The Pod must match a selector in that profile to be scheduled onto Fargate. Kubernetes affinity/anti-affinity rules do not apply and aren't necessary with Amazon EKS Fargate Pods.

Lets start by adding a Fargate profile to our EKS cluster. The command below creates a Fargate profile called `checkout-profile` with the following characteristics:

1. Target Pods in the `checkout` namespace that have the label `fargate: yes`
2. Place pod in the private subnets of the VPC
3. Apply an IAM role to the Fargate infrastructure so that it can pull images from ECR, write logs to CloudWatch and so on

The following command creates the profile, which will take several minutes:

```bash timeout=600
$ aws eks create-fargate-profile \
    --cluster-name ${EKS_CLUSTER_NAME} \
    --pod-execution-role-arn $FARGATE_IAM_PROFILE_ARN \
    --fargate-profile-name checkout-profile \
    --selectors '[{"namespace": "checkout", "labels": {"fargate": "yes"}}]' \
    --subnets "[\"$PRIVATE_SUBNET_1\", \"$PRIVATE_SUBNET_2\", \"$PRIVATE_SUBNET_3\"]"

$ aws eks wait fargate-profile-active --cluster-name ${EKS_CLUSTER_NAME} \
    --fargate-profile-name checkout-profile
```

Now we can inspect the Fargate profile:

```bash wait=120
$ aws eks describe-fargate-profile \
    --cluster-name $EKS_CLUSTER_NAME \
    --fargate-profile-name checkout-profile
{
    "fargateProfile": {
        "fargateProfileName": "checkout-profile",
        "fargateProfileArn": "arn:aws:eks:us-west-2:1234567890:fargateprofile/eks-workshop/checkout-profile/92c4e2e3-50cd-773c-1c32-52e4d44cd0ca",
        "clusterName": "eks-workshop",
        "createdAt": "2023-08-05T12:57:58.022000+00:00",
        "podExecutionRoleArn": "arn:aws:iam::1234567890:role/eks-workshop-fargate",
        "subnets": [
            "subnet-01c3614cdd385a93c",
            "subnet-0e392224ce426565a",
            "subnet-07f8a6fda62ec83df"
        ],
        "selectors": [
            {
                "namespace": "checkout",
                "labels": {
                    "fargate": "yes"
                }
            }
        ],
        "status": "ACTIVE",
        "tags": {}
    }
}
```
