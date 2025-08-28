---
title: Create Graviton Nodes
sidebar_position: 10
---

In this exercise, we'll provision a separate managed node group with Graviton-based instances and apply a taint to it.

To start with lets confirm the current state of nodes available in our cluster:

```bash
$ kubectl get nodes -L kubernetes.io/arch
NAME                                           STATUS   ROLES    AGE     VERSION                ARCH
ip-192-168-102-2.us-west-2.compute.internal    Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
ip-192-168-137-20.us-west-2.compute.internal   Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
ip-192-168-19-31.us-west-2.compute.internal    Ready    <none>   6h56m   vVAR::KUBERNETES_NODE_VERSION      amd64
```

The output shows our existing nodes with columns that show the CPU architecture of each node. All of these are currently using `amd64` nodes.

:::note
We will not yet configure the taints, this is done later.
:::

The following command creates the Graviton node group:

```bash timeout=600 hook=configure-taints
$ aws eks create-nodegroup \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton \
  --node-role $GRAVITON_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --instance-types t4g.medium \
  --ami-type AL2023_ARM_64_STANDARD \
  --scaling-config minSize=1,maxSize=3,desiredSize=1 \
  --disk-size 20
```

:::tip
The aws `eks wait nodegroup-active` command can be used to wait until a specific EKS node group is active and ready for use. This command is part of the AWS CLI and can be used to ensure that the specified node group has been successfully created and all the associated instances are running and ready.

```bash wait=30 timeout=300
$ aws eks wait nodegroup-active \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton
```

:::

Once our new managed node group is **Active**, run the following command:

```bash
$ kubectl get nodes \
    --label-columns eks.amazonaws.com/nodegroup,kubernetes.io/arch

NAME                                          STATUS   ROLES    AGE    VERSION               NODEGROUP   ARCH
ip-192-168-102-2.us-west-2.compute.internal   Ready    <none>   6h56m  vVAR::KUBERNETES_NODE_VERSION     default     amd64
ip-192-168-137-20.us-west-2.compute.internal  Ready    <none>   6h56m  vVAR::KUBERNETES_NODE_VERSION     default     amd64
ip-192-168-19-31.us-west-2.compute.internal   Ready    <none>   6h56m  vVAR::KUBERNETES_NODE_VERSION     default     amd64
ip-10-42-172-231.us-west-2.compute.internal   Ready    <none>   2m5s   vVAR::KUBERNETES_NODE_VERSION     graviton    arm64
```

The below command makes use of the `--selector` flag to query for all nodes that have a label of `eks.amazonaws.com/nodegroup` that matches the name of our managed node group `graviton`. The `--label-columns` flag also allows us to display the value of the `eks.amazonaws.com/nodegroup` label as well as the processor architecture in the output. Note that the `ARCH` column shows our tainted node group running Graviton `arm64` processors.

Let's explore the current configuration of our node. The following command will list the details of all nodes that are part of our managed node group.

```bash
$ kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=graviton
Name:               ip-10-42-12-233.us-west-2.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/instance-type=t4g.medium
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=graviton
                    eks.amazonaws.com/nodegroup-image=ami-0b55230f107a87100
                    eks.amazonaws.com/sourceLaunchTemplateId=lt-07afc97c4940b6622
                    kubernetes.io/arch=arm64
                    [...]
CreationTimestamp:  Wed, 09 Nov 2022 10:36:26 +0000
Taints:             <none>
[...]
```

A few things to point out:

1. EKS automatically adds certain labels to allow for easier filtering, including labels for the OS type, managed node group name, instance type and others. While certain labels are provided out-of-the-box with EKS, AWS allows operators to configure their own set of custom labels at the managed node group level. This ensures that every node within a node group will have consistent labels. The `kubernetes.io/arch` label shows we're running an EC2 instance with an ARM64 CPU architecture.
2. Currently there are no taints configured for the explored node, as shown by the `Taints: <none>` stanza.

## Configuring taints for Managed Node Groups

While it's easy to taint nodes using the `kubectl` CLI as described [here](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#concepts), an administrator will have to make this change every time the underlying node group scales up or down. To overcome this challenge, AWS supports adding both `labels` and `taints` to managed node groups, ensuring every node within the MNG will have the associated labels and taints configured automatically.

Now let's add a taint to our pre-configured managed node group `graviton`. This taint will have `key=frontend`, `value=true` and `effect=NO_EXECUTE`. This ensures that any pods that are already running on our tainted managed node group are evicted if they do not have a matching toleration. Also, no new pods will be scheduled on to this managed node group without an appropriate toleration.

Let's start by adding a `taint` to our managed node group using the following `aws` cli command:

```bash wait=20
$ aws eks update-nodegroup-config \
    --cluster-name $EKS_CLUSTER_NAME --nodegroup-name graviton \
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
```

Run the following command to wait for the node group to become active.

```bash timeout=180
$ aws eks wait nodegroup-active --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton
```

The addition, removal, or replacement of taints can be done by using the [`aws eks update-nodegroup-config`](https://docs.aws.amazon.com/cli/latest/reference/eks/update-nodegroup-config.html) CLI command to update the configuration of the managed node group. This can be done by passing either `addOrUpdateTaints` or `removeTaints` and a list of taints to the `--taints` command flag.

:::tip
You can also configure taints on a managed node group using the `eksctl` CLI. See the [docs](https://eksctl.io/usage/nodegroup-taints/) for more info.
:::

We used `effect=NO_EXECUTE` in our taint configuration. Managed node groups currently support the folowing values for the taint `effect`:

- `NO_SCHEDULE` - This corresponds to the Kubernetes `NoSchedule` taint effect. This configures the managed node group with a taint that repels all pods that don't have a matching toleration. All running pods are **not evicted from the manage node group's nodes**.
- `NO_EXECUTE` - This corresponds to the Kubernetes `NoExecute` taint effect. Allows nodes configured with this taint to not only repel newly scheduled pods but also **evicts any running pods without a matching toleration**.
- `PREFER_NO_SCHEDULE` - This corresponds to the Kubernetes `PreferNoSchedule` taint effect. If possible, EKS avoids scheduling Pods that do not tolerate this taint onto the node.

We can use the following command to check the taints have been correctly configured for the managed node group:

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton \
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
    --selector eks.amazonaws.com/nodegroup=graviton | grep Taints
Taints:             frontend=true:NoExecute
```
