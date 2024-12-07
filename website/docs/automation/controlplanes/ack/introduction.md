---
title: "Introduction"
sidebar_position: 3
---

Each ACK service controller is packaged into a separate container image that is published in a public repository corresponding to an individual ACK service controller. For each AWS service that we wish to provision, resources for the corresponding controller must be installed in the Amazon EKS cluster. Helm charts and official container images for ACK are available [here](https://gallery.ecr.aws/aws-controllers-k8s).

In this section, since we will be working with Amazon DynamoDB ACK, we first need to install the ACK controller by using the Helm chart. As we ran the prepare-environment earlier, a role with proper permision is created for the ACK controller. Now let's create a service account and associate it with that role.
```bash
$ kubectl create ns ack-dynamodb
$ kubectl create sa ack-ddb-sa --namespace ack-dynamodb
$ kubectl annotate serviceaccount -n  ack-dynamodb ack-ddb-sa \
  eks.amazonaws.com/role-arn=$ACK_IAM_ROLE --overwrite
```

Next, let us install the DynamoDB ACK controller by using the following commends: 
```bash
$ aws ecr-public get-login-password --region us-east-1 | \
helm registry login --username AWS --password-stdin public.ecr.aws
$ helm install -n ack-dynamodb ack  \
  oci://public.ecr.aws/aws-controllers-k8s/dynamodb-chart \
  --version=1.1.1  \
  --set=aws.region=$AWS_REGION \
  --set serviceAccount.create=false \
  --set serviceAccount.name=ack-ddb-sa
```

Once the controller is installed, it is running as a deployment in ack-dynamodb namespace. To see what's under the hood, lets run the below.

```bash
$ kubectl get deployment  -n ack-dynamodb
```

