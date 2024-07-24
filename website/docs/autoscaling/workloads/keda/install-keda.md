---
title: "Installing KEDA"
sidebar_position: 5
---

First lets install KEDA using Helm. One pre-requisite was created during the lab preparation stage. An IAM role was created with permissions to access the metric data within CloudWatch.

```bash
$ helm repo add kedacore https://kedacore.github.io/charts
$ helm upgrade --install keda kedacore/keda \
  --version "${KEDA_CHART_VERSION}" \
  --namespace keda \
  --create-namespace \
  --set "podIdentity.aws.irsa.enabled=true" \
  --set "podIdentity.aws.irsa.roleArn=${KEDA_ROLE_ARN}" \
  --wait
Release "keda" does not exist. Installing it now.
NAME: keda
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
[...]
```

After the Helm install, KEDA will be running as several deployments in the keda namespace:

```bash
$ kubectl get deployment -n keda
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
keda-admission-webhooks           1/1     1            1           105s
keda-operator                     1/1     1            1           105s
keda-operator-metrics-apiserver   1/1     1            1           105s
```

Each KEDA deployment performs a different key role:

1. Agent (keda-operator) - controls the scaling of the workload
2. Metrics (keda-operator-metrics-server) - acts as a Kubernetes metrics server, providing access to external metrics
3. Admission Webhooks (keda-admission-webhooks) - validates resource configuration to prevent misconfiguration (ex. multiple ScaledObjects targeting the same workload)

Now we can move on to configuring KEDA to scale our workload.
