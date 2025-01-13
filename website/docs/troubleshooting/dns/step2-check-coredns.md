---
title: "Checking CoreDNS pods"
sidebar_position: 52
---

In EKS clusters, DNS resolution is performed by CoreDNS pods. We need to ensure that CoreDNS pods are running without errors.

Check CoreDNS pods in kube-system namespace:

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
CoreDNS-6fdb8f5699-dq7xw   0/1     Pending   0          42s
CoreDNS-6fdb8f5699-z57jw   0/1     Pending   0          42s
```

CoreDNS pods are not running!
This is definitely a problem that affect DNS Resolution in the cluster.

CoreDNS pods show in Pending state, which indicates that pods has not been scheduled to any node.
Check pod description to know what happened during pod scheduling.

Describe CoreDNS pods and analyze the Events section:

```bash timeout=30
$ kubectl describe po -l k8s-app=kube-dns -n kube-system
...
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  29s   default-scheduler  0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

The Warning message indicates that node label don't match CoreDNS pod node selector or affinity.

Check CoreDNS pod node selector:

```bash timeout=30
$ kubectl get deployment CoreDNS -n kube-system -o jsonpath='{.spec.template.spec.nodeSelector}' | jq
{
  "workshop-default": "no"
}
```

Now let's check whether worker node have this label:

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

The last line of the output shows node label `"workshop-default": "yes"`. However, CoreDNS pod node selector uses label `"workshop-default": "no"`.

We found the problem: CoreDNS node selector doesn't match existing node labels.

### Root Cause

In the real world, users may use node selectors with CoreDNS to ensure that CoreDNS pods run on specific nodes, dedicated to cluster kube-system controllers.
When using node selectors, keep in mind that if selector and node label don't match, pods can get stuck in Pending state and never run.

In this case, CoreDNS addon was updated to use a node-selector that doesn't match any of the existing node. Then, CoreDNS pods are stuck in Pending state.

### How to resolve this issue?

To resolve this issue, update CoreDNS addon to use its default configuration, which removes nodeSelector requirements and allows CoreDNS pods to run any of the worker nodes.

Update CoreDNS addon using empty custom configuration and wait for the addon update to complete:

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
        "createdAt": "2024-11-09T16:25:15.885000-05:00",
        "errors": []
    }
}
$ aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --region $AWS_REGION  --addon-name coredns
```

Now, CoreDNS pod show up in Running state

```bash timeout=30
$ kubectl get pod -l k8s-app=kube-dns -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
CoreDNS-7f6dd6865f-7qcjr   1/1     Running   0          100s
CoreDNS-7f6dd6865f-kxw2x   1/1     Running   0          100s
```

As additional step, verify that CoreDNS application is not showing any errors. For that, let's check CoreDNS logs.

Check CoreDNS pod logs:

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

CoreDNS logs don't show errors, which means that CoreDNS application should be processing DNS requests as expected.

### Next Steps

At this point, we have resolved the problem with CoreDNS pods and ensured that CoreDNS application is running without errors.

Let's continue to the next lab to cover additional troubleshooting steps and ensure every aspect of DNS resolution is correct.
