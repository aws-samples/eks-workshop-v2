---
title: Configuring taints
sidebar_position: 10
---

For the purpose of this exercise we'll provision a separate managed node group which we'll apply taints to. 

```file
manifests/modules/fundamentals/mng/taints/nodegroup.yaml
```

Note: This configuration file does not yet configure the taints, it only applies a label `tainted: 'yes'`. We will configure the taints on this node group further below.

The following command create this node group:

```bash timeout=600 hook=configure-taints
$ cat ~/environment/eks-workshop/modules/fundamentals/mng/taints/nodegroup.yaml | envsubst | eksctl create nodegroup -f -
```

It will take *2-3* minutes for the node to join the EKS cluster, until you see this command give the following output:

```bash
$ kubectl get nodes \
    --label-columns eks.amazonaws.com/nodegroup \
    --selector eks.amazonaws.com/nodegroup=taint-mng
NAME                                         STATUS   ROLES    AGE   VERSION               NODEGROUP
ip-10-42-12-233.us-west-2.compute.internal   Ready    <none>   63m   vVAR::KUBERNETES_NODE_VERSION   taint-mng
```

The above command makes use of the `--selector` flag to query for all nodes that have a label of `eks.amazonaws.com/nodegroup` that matches the name of our managed node group `taint-mng`. The `--label-columns` flag also allows us to display the value of the `eks.amazonaws.com/nodegroup` label in the node list. 

Before configuring our taints, let's explore the current configuration of our node. Note that the following command will list the details of all nodes that are part of our managed node group. In our lab, the managed node group has just one instance. 

```bash
$ kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=taint-mng
Name:               ip-10-42-12-233.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/instance-type=t3.medium
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=taint-mng
                    eks.amazonaws.com/nodegroup-image=ami-0b55230f107a87100
                    eks.amazonaws.com/sourceLaunchTemplateId=lt-07afc97c4940b6622
                    [...]
CreationTimestamp:  Wed, 09 Nov 2022 10:36:26 +0000
Taints:             <none>
[...]
```

A few things to point out:

1. EKS automatically adds certain labels to allow for easier filtering, including labels for the OS type, managed node group name, instance type and others. While certain labels are provided out-of-the-box with EKS, AWS allows operators to configure their own set of custom labels at the managed node group level. This ensures that every node within a node group will have consistent labels. 
2. Currently, there are no taints configured for the explored node, showcased by the `Taints: <none>` stanza. 

## Configuring taints for Managed Node Groups

While it's easy to taint nodes using the `kubectl` CLI as described [here](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#concepts), an administrator will have to make this change every time the underlying node group scales up or down. To overcome this challenge, AWS supports adding both `labels` and `taints` to managed node groups, ensuring every node within the MNG will have the associated labels and taints configured automatically. 

In the next few sections, we'll explore how to add taints to our preconfigured managed node group `taint-mng`. 

Let's start by adding a `taint` to our managed node group using the following `aws` cli command: 

```bash timeout=180
$ aws eks update-nodegroup-config \
    --cluster-name $EKS_CLUSTER_NAME \
    --nodegroup-name taint-mng \
    --taints "addOrUpdateTaints=[{key=frontend, value=true, effect=NO_EXECUTE}]"
{
    "update": {
        "id": "488a2b7d-9194-3032-974e-2f1056ef9a1b",
        "status": "InProgress",
        "type": "ConfigUpdate",
        "params": [
            {
                "type": "TaintsToAdd",
                "value": "[{\"effect\":\"NO_EXECUTE\",\"value\":\"true\",\"key\":\"frontend\"}]"
            }
        ],
        "createdAt": "2022-11-09T15:20:10.519000+00:00",
        "errors": []
    }
}
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name taint-mng
```

The addition, removal, or replacement of taints can be done by using the [`aws eks update-nodegroup-config`](https://docs.aws.amazon.com/cli/latest/reference/eks/update-nodegroup-config.html) CLI command to update the configuration of the managed node group. This can be done by passing either `addOrUpdateTaints` or `removeTaints` and a list of taints to the `--taints` command flag. 

The above command will add a new taint with the key of `frontend`, value of `true` and effect of `NO_EXECUTE`. This ensures that pods will not be able to be scheduled on any nodes that are part of the managed node group without having the corresponding toleration. Also, any existing pods without a matching toleration will be evicted. 

:::tip
You can also configure taints on a managed node group using the `eksctl` CLI. See the [docs](https://eksctl.io/usage/nodegroup-taints/) for more info.
:::

The configuration for managed node groups currently support the folowing values for the taint `effect`:
* `NO_SCHEDULE` - This corresponds to the Kubernetes `NoSchedule` taint effect. This configures the managed node group with a taint that repels all pods that don't have a matching toleration. All running pods are **not evicted from the manage node group's nodes**.
* `NO_EXECUTE` - This corresponds to the Kubernetes `NoExecute` taint effect. Allows nodes configured with this taint to not only repel newly scheduled pods but also **evicts any running pods without a matching toleration**.
* `PREFER_NO_SCHEDULE` - This corresponds to the Kubernetes `PreferNoSchedule` taint effect. If possible, EKS avoids scheduling Pods that do not tolerate this taint onto the node.

We can use the following command to check the taints have been correctly configured for the managed node group:

```bash
$ aws eks describe-nodegroup \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name taint-mng \
  | jq .nodegroup.taints
[
  {
    "key": "frontend",
    "value": "true",
    "effect": "NO_EXECUTE"
  }
]
```

:::info

Updating the managed node group and propagating the labels and taints usually takes a few minutes. If you're not seeing any taints configured or getting a `null` value, please do wait a few minutes before trying the above command again. 

:::

Verifying with the `kubectl` cli command, we can also see that the taint has been correctly propagated to the associated node:

```bash
$ kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=taint-mng | grep Taints
Taints:             frontend=true:NoExecute
```
