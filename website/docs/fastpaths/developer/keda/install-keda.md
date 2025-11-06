---
title: "Installing KEDA"
sidebar_position: 5
---

First let's install KEDA using Helm. An IAM role with permissions to access metric data within CloudWatch was created when the Auto Mode cluster was set up.

With Amazon EKS Auto Mode, we'll use EKS Pod Identity instead of IRSA. Let's create the Pod Identity association:

```bash
$ export KEDA_ROLE_ARN=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_AUTO_NAME}-keda
$ aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_AUTO_NAME} \
  --role-arn ${KEDA_ROLE_ARN} \
  --namespace keda --service-account keda-operator | jq .
```

Now install KEDA:

```bash
$ export KEDA_CHART_VERSION=$(grep -oP 'default\s*=\s*"\K[^"]+' ~/environment/eks-workshop/modules/autoscaling/workloads/keda/.workshop/terraform/vars.tf | tail -1)
$ helm repo add kedacore https://kedacore.github.io/charts
$ helm upgrade --install keda kedacore/keda \
  --version "${KEDA_CHART_VERSION}" \
  --namespace keda \
  --create-namespace \
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
