---
title: Configuring taints
sidebar_position: 10
---

Before we start, let's explore the already configured managed node group (MNG) using the following command: 

```bash
$ eksctl get nodegroup \
    --name $EKS_TAINTED_MNG_NAME \
    --cluster $EKS_CLUSTER_NAME
CLUSTER			NODEGROUP						STATUS	CREATED			MIN SIZE	MAX SIZE	DESIRED CAPACITY	INSTANCE TYPE	IMAGE ID		ASG NAME									TYPE
eks-workshop-cluster	managed-ondemand-tainted-20221103142426393800000006	ACTIVE	2022-11-03T14:24:28Z	1		2		1			m5.large	ami-0b55230f107a87100	eks-managed-ondemand-tainted-20221103142426393800000006-d0c21ef0-8024-f793-52a9-3ed57ca9d457	managed
```

For the purpose of the lab, we have provisioned a separate `managed` node group with a desired capacity of `1` and instance type of `m5.large`. We can validate this configuration using `kubectl` as follows:

```bash
$ kubectl get nodes \
    -L eks.amazonaws.com/nodegroup \
    -l eks.amazonaws.com/nodegroup=$EKS_TAINTED_MNG_NAME
NAME                                         STATUS   ROLES    AGE   VERSION               NODEGROUP
ip-10-42-12-233.eu-west-1.compute.internal   Ready    <none>   63m   v1.23.9-eks-ba74326   managed-ondemand-tainted-20221103142426393800000006
```

Bofore configuring our taints, let's explore the current configuration of our node. Note that the following command will list the details of all nodes that are part of our Managed Node Group. In our lab, this is just one instance. 

```bash
$ kubectl describe nodes \
    -l eks.amazonaws.com/nodegroup=$EKS_TAINTED_MNG_NAME
Name:               ip-10-42-12-233.eu-west-1.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/instance-type=m5.large
                    beta.kubernetes.io/os=linux
                    eks.amazonaws.com/capacityType=ON_DEMAND
                    eks.amazonaws.com/nodegroup=managed-ondemand-tainted-20221103142426393800000006
                    eks.amazonaws.com/nodegroup-image=ami-0b55230f107a87100
                    eks.amazonaws.com/sourceLaunchTemplateId=lt-07afc97c4940b6622
                    [...]
CreationTimestamp:  Wed, 09 Nov 2022 10:36:26 +0000
Taints:             <none>
[...]
```

A few things to point out:
1. EKS automatically adds certain labels to allow for easier filtering. We have used the `eks.amazonaws.com/nodegroup` label to filter out all nodes that are part of the node group we are interested in. While certain labels are provided out-of-the-box with EKS, we also allow operators to configure their own set of labels at the node group level. This ensures that every node within a node group will have consistent labels. 
2. There are no taints configured for the explored node, showcased by the `Taints: <none>` stanza. 


## Configuring taints for Managed Node Groups (MNGs)

While it's easy to taint nodes using the `kubectl` CLI as described [here](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#concepts), an administrator will have to make this change every time the underlying node group scales up or down. To overcome this challange, AWS supports adding both `labels` and `taints` to managed node groups, ensuring every node within the MNG will have the asociated labels and taints configured automatically. 

In the next few sections, will explore how to add taints to the preconfigured managed node group. 

Let's start by adding a `taint` to our managed node group using the following `aws` cli command: 

```bash
$ aws eks update-nodegroup-config \
    --cluster-name $EKS_CLUSTER_NAME \
    --nodegroup-name $EKS_TAINTED_MNG_NAME \
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

The above command will add a new taint with the key of `frontend`, value of `true` and effect of `NO_EXECUTE`. This ensures that pods will not be able to be scheduled on any nodes that are part of the managed node group without having the corresponding toleration. Also, any existing pods without a matching toleration will be evicted. The configuration for MNG currently support the folowing values for `effect`:
* `NO_SCHEDULE`
* `NO_EXECUTE`
* `PREFER_NO_SCHEDULE`

We can use the following command to check the taints have been correctly configured for the managed node group:

```bash
$ aws eks describe-nodegroup \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name $EKS_TAINTED_MNG_NAME \
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

Updating the managed node group and propagating the labels and taints usually takes a few minutes. If you are not seeing any taints configured or getting a `null` value, please do wait a few minutes before trying the above command again. 

:::

Verifying with the `kubectl` cli command, we can also see that the taint has been correctly propagated to the associated node:

```bash
$ kubectl describe nodes \
    -l eks.amazonaws.com/nodegroup=$EKS_TAINTED_MNG_NAME
Name:               ip-10-42-12-233.eu-west-1.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/instance-type=m5.large
                    beta.kubernetes.io/os=linux
                    [...]
CreationTimestamp:  Wed, 09 Nov 2022 10:36:26 +0000
Taints:             frontend=true:NoExecute
```