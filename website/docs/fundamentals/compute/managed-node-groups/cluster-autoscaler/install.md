---
title: "Installation"
sidebar_position: 30
---

The first thing we'll do is install cluster-autoscaler in our cluster. As part of the lab preparation an IAM role has already been created for cluster-autoscaler to call the appropriate AWS APIs.

All that we have left to do is install cluster-autoscaler as a helm chart:

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

It will be running as a deployment in the `kube-system` namespace:

```bash
$ kubectl get deployment -n kube-system cluster-autoscaler-aws-cluster-autoscaler
NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE
cluster-autoscaler-aws-cluster-autoscaler   1/1     1            1           51s
```

Now we can move on to modifying our workloads to trigger the provisioning of more compute.
