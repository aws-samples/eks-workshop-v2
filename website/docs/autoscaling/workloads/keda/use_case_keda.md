---
title: "Use Case"
sidebar_position: 20
---

In this example, we will use KEDA to scale nginx pod in namespace `sample` based on number of SQS messages in the queue.

First, we create ScaledObjects:

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: aws-sqs-queue
  namespace: sample
spec:
  scaleTargetRef:
    name: sample-app
  triggers:
  - type: aws-sqs-queue
    metadata:
      queueURL: https://sqs.eu-central-1.amazonaws.com/<account_id>/test-queue-1
      queueLength: "5"
      awsRegion: "eu-central-1" #it just an example
      identityOwner: operator
```

* `queueURL` - Full URL for the SQS Queue
* `queueLength` - Target value for queue length passed to the scaler. (number of message that could be handled by one pod on the same time)
* `awsRegion` - AWS Region for the SQS Queue
* `identityOwner` - Receive permissions on the SQS Queue via Pod Identity or from the KEDA operator itself (see below).
* `scaleTargetRef`: name of the deployment to be scaled in the namespace.

Verify if the ScaledObject is ready

```bash
+ kubectl get scaledobject
NAME            SCALETARGETKIND      SCALETARGETNAME   MIN   MAX   TRIGGERS        AUTHENTICATION   READY   ACTIVE   AGE
aws-sqs-queue   apps/v1.Deployment   sample-app                    aws-sqs-queue                    True    False    41d
```

Then, we use this small bash script to create and send sqs message in the queue.

```bash
for i in {1..50}
do
aws sqs send-message --region eu-central-1 --endpoint-url https://sqs.eu-central-1.amazonaws.com/ --queue-url https://sqs.eu-central-1.amazonaws.com/<account_id>/test-queue-1 --message-body "Hello from Amazon SQS. message ${i}"
done
```

Once the ScaledObject becames  ACTIVE, then, it set an HPA pod to 10 (note that we set queue length to 5 and we sent 50 messages in the queue)

```bash
+ kubectl get so
NAME SCALETARGETKIND SCALETARGETNAME MIN MAX TRIGGERS AUTHENTICATION READY ACTIVE AGE
aws-sqs-queue apps/v1.Deployment sample-app aws-sqs-queue True True 6m23s

+ kubectl get hpa
NAME                     REFERENCE               TARGETS     MINPODS   MAXPODS   REPLICAS   AGE
keda-hpa-aws-sqs-queue   Deployment/sample-app   5/5 (avg)   1         100       10         8m44s

+ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
sample-app-5d9cd5464f-2jgkz   1/1     Running   0          4m23s
sample-app-5d9cd5464f-56r9d   1/1     Running   0          4m10s
sample-app-5d9cd5464f-5thn8   1/1     Running   0          4m10s
sample-app-5d9cd5464f-7xlfw   1/1     Running   0          4m40s
sample-app-5d9cd5464f-jgz2v   1/1     Running   0          4m10s
sample-app-5d9cd5464f-k42fd   1/1     Running   0          4m10s
sample-app-5d9cd5464f-k5692   1/1     Running   0          4m23s
sample-app-5d9cd5464f-phvrn   1/1     Running   0          4m40s
sample-app-5d9cd5464f-t4dq8   1/1     Running   0          4m40s
sample-app-5d9cd5464f-wtmrr   1/1     Running   0          4m44s
```

Once the messages were consumed or purged from the queue, KEDA will scale down the number of pods on HPA configuration.

More details check keda documentations: <https://keda.sh/>
