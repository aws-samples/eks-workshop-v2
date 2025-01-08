---
title: "Introduction"
sidebar_position: 3
---

Each ACK service controller is packaged into a separate container image that is published in a public repository corresponding to an individual ACK service controller. For each AWS service that we wish to provision, resources for the corresponding controller must be installed in the Amazon EKS cluster. Helm charts and official container images for ACK are available [here](https://gallery.ecr.aws/aws-controllers-k8s).

In this section, since we'll be working with Amazon DynamoDB ACK, we first need to install that ACK controller by using the Helm chart:

```bash wait=60
$ aws ecr-public get-login-password --region us-east-1 | \
  helm registry login --username AWS --password-stdin public.ecr.aws
$ helm install ack-dynamodb  \
  oci://public.ecr.aws/aws-controllers-k8s/dynamodb-chart \
  --version=${DYNAMO_ACK_VERSION} \
  --namespace ack-system --create-namespace \
  --set "aws.region=${AWS_REGION}" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$ACK_IAM_ROLE" \
  --wait
```

The controller will be running as a deployment in the `ack-system` namespace:

```bash
$ kubectl get deployment -n ack-system
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
ack-dynamodb-dynamodb-chart   1/1     1            1           13s
```
