---
title: "Install KEDA with helm"
sidebar_position: 10
---

In this setup, we are going to use helm chart to deploy KEDA on EKS and AWS SQS as an external trigger source. KEDA operator should use the [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) to gain access to the AWS services (AWS SQS). We will use this IAM policy to restrict the access to only the sqs queue with prefix `test-queue-`.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ReadSqsQueue",
            "Effect": "Allow",
            "Action": [
                "sqs:ListQueues",
                "sqs:ListDeadLetterSourceQueues",
                "sqs:GetQueueUrl",
                "sqs:GetQueueAttributes"
            ],
            "Resource": "arn:aws:sqs:*:<account_id>:test-queue-*"
        }
    ]
}

```

Then, we deploy KEDA helm charts using the below values:

```yaml
image:
  keda:
    repository: ghcr.io/kedacore/keda
  metricsApiServer:
    repository: ghcr.io/kedacore/keda-metrics-apiserver
  pullPolicy: Always

rbac:
  create: true

serviceAccount:
  create: true
  name: keda-operator
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<account_id>:role/iam-role-keda

podSecurityContext:
  fsGroup: 2000

securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: false #false: in case you are use selfsigned certs for keda
  runAsNonRoot: true
  runAsUser: 1000

service:
  type: ClusterIP
  portHttp: 80
  portHttpTarget: 8080
  portHttps: 443
  portHttpsTarget: 6443

  annotations: {}

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

env:
  - name: AWS_STS_REGIONAL_ENDPOINTS
    value: 'regional'
```

Finally, we deploy helm release:

```bash
helm repo add kedacore https://kedacore.github.io/charts
kubectl create namespace keda
helm install keda kedacore/keda --namespace keda -f values.yaml
```
