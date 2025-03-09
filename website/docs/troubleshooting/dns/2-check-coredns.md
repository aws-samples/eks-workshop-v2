---
title: "Checking CoreDNS pods"
sidebar_position: 52
---

In EKS clusters, CoreDNS pods handle DNS resolution. Let's verify that these pods are running correctly.

### Step 1 - Check pod status

First, check CoreDNS pods in the kube-system namespace:

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
CoreDNS-6fdb8f5699-dq7xw   0/1     Pending   0          42s
CoreDNS-6fdb8f5699-z57jw   0/1     Pending   0          42s
```

We can see that CoreDNS pods are not running which clearly explains the DNS resolution issues in the cluster.

:::info
The pods are in Pending state, indicating they haven't been scheduled to any node. 
:::

### Step 2 - Check pod events

Let's investigate further by checking events related to these pods in their descriptions:

```bash timeout=30
$ kubectl describe po -l k8s-app=kube-dns -n kube-system | sed -n '/Events:/,/^$/p'

Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  29s   default-scheduler  0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

The warning message indicates a mismatch between node labels and the CoreDNS pod node selector/affinity.

### Step 3 - Check node selection

Let's examine the CoreDNS pod node selector:

```bash timeout=30
$ kubectl get deployment CoreDNS -n kube-system -o jsonpath='{.spec.template.spec.nodeSelector}' | jq
{
  "workshop-default": "no"
}
```

Now, check the worker node labels:

```bash timeout=30
$ kubectl get node -o jsonpath='{.items[0].metadata.labels}' | jq
{
  "alpha.eksctl.io/cluster-name": "eks-workshop",
  "alpha.eksctl.io/nodegroup-name": "default",
  "beta.kubernetes.io/arch": "amd64",
  "beta.kubernetes.io/instance-type": "m5.large",
  "beta.kubernetes.io/os": "linux",
  "eks.amazonaws.com/capacityType": "ON_DEMAND",
  "eks.amazonaws.com/nodegroup": "default",
  "eks.amazonaws.com/nodegroup-image": "ami-07fdc65a0c344a252",
  "eks.amazonaws.com/sourceLaunchTemplateId": "lt-0f7c7c3c9cb770aaa",
  "eks.amazonaws.com/sourceLaunchTemplateVersion": "1",
  "failure-domain.beta.kubernetes.io/region": "us-west-2",
  "failure-domain.beta.kubernetes.io/zone": "us-west-2a",
  "k8s.io/cloud-provider-aws": "b2c4991f4c3acb5b142be2a5d455731a",
  "kubernetes.io/arch": "amd64",
  "kubernetes.io/hostname": "ip-10-42-100-65.us-west-2.compute.internal",
  "kubernetes.io/os": "linux",
  "node.kubernetes.io/instance-type": "m5.large",
  "topology.k8s.aws/zone-id": "usw2-az1",
  "topology.kubernetes.io/region": "us-west-2",
  "topology.kubernetes.io/zone": "us-west-2a",
  "workshop-default": "yes"
}
```

The CoreDNS pod requires nodes with label `workshop-default: no`, however the nodes are labeled with `workshop-default: yes`.

:::info
There are different options in pod's yaml manifest to influence pod scheduling on nodes. Other parameters include affinity, anti-affinity, and pod topology spread constraints. More details in the [Kubernetes documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/).
:::

### Root Cause

In production environments, teams often use node selectors with CoreDNS to run these pods on dedicated nodes for cluster system components. However, if the selectors don't match node labels, pods remain in Pending state.

In this case, the CoreDNS addon was configured with a node selector that doesn't match any existing nodes, preventing the pods from running.

### Resolution

To fix this, we'll update the CoreDNS addon to use its default configuration, removing the nodeSelector requirements:

```bash timeout=180
$ aws eks update-addon \
    --cluster-name $EKS_CLUSTER_NAME \
    --region $AWS_REGION \
    --addon-name coredns \
    --resolve-conflicts OVERWRITE \
    --configuration-values '{}'
{
    "update": {
        "id": "b3e7d81c-112a-33ea-bb28-1b1052bc3969",
        "status": "InProgress",
        "type": "AddonUpdate",
        "params": [
            {
                "type": "ResolveConflicts",
                "value": "OVERWRITE"
            },
            {
                "type": "ConfigurationValues",
                "value": "{}"
            }
        ],
        "createdAt": "20XX-XX-09T16:25:15.885000-05:00",
        "errors": []
    }
}
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name coredns
```

Then verify that CoreDNS pods are now running:

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
CoreDNS-7f6dd6865f-7qcjr   1/1     Running   0          100s
CoreDNS-7f6dd6865f-kxw2x   1/1     Running   0          100s
```

Finally, check CoreDNS logs to ensure the application is running without errors:

```bash timeout=30
$ kubectl logs -l k8s-app=kube-dns -n kube-system
.:53
[INFO] plugin/reload: Running configuration SHA512 = 8a7d59126e7f114ab49c6d2613be93d8ef7d408af8ee61a710210843dc409f03133727e38f64469d9bb180f396c84ebf48a42bde3b3769730865ca9df5eb281c
CoreDNS-1.11.1
linux/amd64, go1.21.5, e9c721d80
.:53
[INFO] plugin/reload: Running configuration SHA512 = 8a7d59126e7f114ab49c6d2613be93d8ef7d408af8ee61a710210843dc409f03133727e38f64469d9bb180f396c84ebf48a42bde3b3769730865ca9df5eb281c
CoreDNS-1.11.1
linux/amd64, go1.21.5, e9c721d80
```

The logs show no errors, indicating that CoreDNS is now processing DNS requests correctly.

### Next Steps

We've resolved the CoreDNS pod scheduling issue and verified the application is running properly. Let's proceed to the next lab for additional DNS resolution troubleshooting steps.