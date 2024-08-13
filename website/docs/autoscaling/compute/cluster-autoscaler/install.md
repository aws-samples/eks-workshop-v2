
---
title: "Installation"
sidebar_position: 30
---

First, we'll install cluster-autoscaler in our cluster. As part of the lab preparation, an IAM role has already been created for cluster-autoscaler to call the appropriate AWS APIs.

All that remains is to install cluster-autoscaler as a Helm chart:

```bash
$ helm repo add autoscaler https://kubernetes.github.io/autoscaler
$ helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --version "${CLUSTER_AUTOSCALER_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "autoDiscovery.clusterName=${EKS_CLUSTER_NAME}" \
  --set "awsRegion=${AWS_REGION}" \
  --set "image.tag=v${CLUSTER_AUTOSCALER_IMAGE_TAG}" \
  --set "rbac.serviceAccount.name=cluster-autoscaler-sa" \
  --set "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$CLUSTER_AUTOSCALER_ROLE" \
  --wait
NAME: cluster-autoscaler
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

It will run as a deployment in the `kube-system` namespace:

```bash
$ kubectl get deployment -n kube-system cluster-autoscaler-aws-cluster-autoscaler
NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE
cluster-autoscaler-aws-cluster-autoscaler   1/1     1            1           51s
```

Now we can proceed to modify our workloads to trigger the provisioning of more compute resources.
