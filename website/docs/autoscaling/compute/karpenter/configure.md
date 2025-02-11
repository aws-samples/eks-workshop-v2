---
title: "Install Karpenter"
sidebar_position: 20
---

The first thing we'll do is install Karpenter in our cluster. Various pre-requisites were created during the lab preparation stage, including:

1. An IAM role for Karpenter to call AWS APIs
2. An IAM role and instance profile for the EC2 instances that Karpenter creates
3. An EKS cluster access entry for the node IAM role so the nodes can join the EKS cluster
4. An SQS queue for Karpenter to receive Spot interruption, instance re-balance and other events

You can find the full installation documentation for Karpenter [here](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/).

All that we have left to do is install Karpenter as a helm chart:

```bash
$ aws ecr-public get-login-password \
  --region us-east-1 | helm registry login \
  --username AWS \
  --password-stdin public.ecr.aws
$ helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "${KARPENTER_VERSION}" \
  --namespace "karpenter" --create-namespace \
  --set "settings.clusterName=${EKS_CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${KARPENTER_SQS_QUEUE}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --set replicas=1 \
  --wait
NAME: karpenter
LAST DEPLOYED: [...]
NAMESPACE: karpenter
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

Karpenter will be running as a deployment in the `karpenter` namespace:

```bash
$ kubectl get deployment -n karpenter
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   1/1     1            1           105s
```

Now we can move on to configuring Karpenter so that it will provision infrastructure for our pods.
