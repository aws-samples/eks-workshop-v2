---
title: Taints
sidebar_position: 40
---

Taints are a property of a node to repel certain pods. Tolerations are applied to pods to allow their scheduling onto nodes with matching taints. Taints and tolerations work together to ensure that pods are not scheduled on unsuitable nodes. While tolerations allow pods to be scheduled on nodes with matching taint, this isn't a guarentee and other Kuberenetes concepts like node affinity will have to be used to achieve desiered configuration. 

The configuration of tainted nodes is useful in scenarios where we need to ensure that only specific pods are to be scheduled on certain node groups with special hardware (such as attached GPUs) or when we want to dedicate entire node groups to a particular set of Kubernetes users. 

In this section we will learn how to configure taints for our managed node groups. 

## Understanding the current Managed Node Group (MNG) configuration. 

Before we start, let's explore the already configured Managed Node group using the following command: 

```bash
$ eksctl get nodegroup \
    --name managed-ondemand-tainted-20221103142426393800000006 \
    --cluster eks-workshop-cluster
CLUSTER			NODEGROUP						STATUS	CREATED			MIN SIZE	MAX SIZE	DESIRED CAPACITY	INSTANCE TYPE	IMAGE ID		ASG NAME									TYPE
eks-workshop-cluster	managed-ondemand-tainted-20221103142426393800000006	ACTIVE	2022-11-03T14:24:28Z	1		2		1			m5.large	ami-0b55230f107a87100	eks-managed-ondemand-tainted-20221103142426393800000006-d0c21ef0-8024-f793-52a9-3ed57ca9d457	managed
```

For the purpose of the lab, we have provisioned a separate `managed` node group with a desired capacity of `1` and instance type of `m5.large`. We can validate this configuration using `kubectl` as follows:

```bash
$ kubectl describe nodes \
    -L eks.amazonaws.com/nodegroup \
    -l eks.amazonaws.com/nodegroup=$EKS_MANAGED_NODE_GROUP_TAINTED
NAME                                         STATUS   ROLES    AGE   VERSION               NODEGROUP
ip-10-42-12-233.eu-west-1.compute.internal   Ready    <none>   63m   v1.23.9-eks-ba74326   managed-ondemand-tainted-20221103142426393800000006
```

Bofore configuring our taints, let's explore the current configuration of our node. Note that the following command will list the details of all nodes that are part of our Managed Node Group. 

```bash
$ kubectl describe nodes \
    -l eks.amazonaws.com/nodegroup=$EKS_MANAGED_NODE_GROUP_TAINTED
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

While it's easy to taint nodes using the `kubectl` CLI as described [here](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#concepts), an administrator will have to make this change every time the underlying node group scales up and down. To overcome this challange, the EKS supports adding both `labels` and `taints` to managed node groups, ensuring every node within the MNG will have the asociated labels and taints configured automatically. 

In the next few sections, will explore how to add taints to the preconfigured managed node group. 

Let's start by adding a `taint` to our managed node group using the following `aws` cli command: 

```bash
$ aws eks update-nodegroup-config \
    --cluster-name eks-workshop-cluster \
    --nodegroup-name managed-ondemand-tainted-20221103142426393800000006 \
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
  --cluster-name eks-workshop-cluster \
  --nodegroup-name managed-ondemand-tainted-20221103142426393800000006 \
  | jq .nodegroup.taints
[
  {
    "key": "frontend",
    "value": "true",
    "effect": "NO_EXECUTE"
  }
]
```

Verifying with the `kubectl` cli command, we can also see that the taint has been correctly propagated to the associated node:

```bash
$ kubectl describe nodes \
    -l eks.amazonaws.com/nodegroup=$EKS_MANAGED_NODE_GROUP_TAINTED
Name:               ip-10-42-12-233.eu-west-1.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/instance-type=m5.large
                    beta.kubernetes.io/os=linux
                    [...]
CreationTimestamp:  Wed, 09 Nov 2022 10:36:26 +0000
Taints:             frontend=true:NoExecute
```

## Updating our UI service to use tolerations 

Before making any changes, let's check the current configuration for the UI pods. Keep in mind that these pods are being controlled by an associated deployment.

```bash
$ kubectl describe pod --namespace ui -l app.kubernetes.io/name=ui
Name:             ui-7bdbf967f9-qzh7f
Namespace:        ui
Priority:         0
Service Account:  ui
Node:             ip-10-42-11-43.eu-west-1.compute.internal/10.42.11.43
Start Time:       Wed, 09 Nov 2022 16:40:32 +0000
Labels:           app.kubernetes.io/component=service
                  app.kubernetes.io/created-by=eks-workshop
                  app.kubernetes.io/instance=ui
                  app.kubernetes.io/name=ui
                  pod-template-hash=7bdbf967f9
Status:           Running
[....]
Controlled By:  ReplicaSet/ui-7bdbf967f9
Containers:
[...]
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
```
Although there are no tolerations configured in our spec files, a few default ones have been automatically assigned. It's important to recognise that although we have configured one of the existing node groups with a taint (`frontend=true:NoExecute`) the pod is still running as expected. This is because the UI deployment and associated pod is currently scheduled on nodes that are part of a different managed node group. 

The next couple of commands will help us update the `UI` deployment with a corresponding toleration to allow it to be scheduled on our tainted nodes. As previosly stated, configuring tolerations is not enough to ensure pods can **only** be scheduled on our tainted nodes. As such, we will need also need to make use of `NodeSelector` to specifically choose our tainted node. The following `Kustomize` patch describes the changes we need to make to our deployment to enable this configuration: 

```kustomization
fundamentals/mng/taints/deployment.yaml
Deployment/ui
```
To apply the Kustomize changes run the following command: 

```bash
$ kubectl apply -k /workspace/modules/fundamentals/mng/taints/
namespace/ui unchanged
serviceaccount/ui unchanged
configmap/ui unchanged
service/ui unchanged
deployment.apps/ui configured
```
Checking the UI pod, we can see that the configuration now includes the specified toleration (`frontend=true:NoExecute`) and it's scheduled on the node with corresponding taint. 

```bash
$ kubectl describe pod --namespace ui -l app.kubernetes.io/name=ui
Name:             ui-6c5c9f6b5f-pfltt
Namespace:        ui
Priority:         0
Service Account:  ui
Node:             ip-10-42-12-233.eu-west-1.compute.internal/10.42.12.233
Start Time:       Wed, 09 Nov 2022 17:41:42 +0000
Labels:           app.kubernetes.io/component=service
                  app.kubernetes.io/created-by=eks-workshop
                  app.kubernetes.io/instance=ui
                  app.kubernetes.io/name=ui
                  pod-template-hash=6c5c9f6b5f
Controlled By:  ReplicaSet/ui-6c5c9f6b5f
Containers:
[...]
Node-Selectors:              tainted=yes
Tolerations:                 frontend:NoExecute op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
[...]
$ kubectl describe node -l tainted=yes
Name:               ip-10-42-12-233.eu-west-1.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    [...]
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=ip-10-42-12-233.eu-west-1.compute.internal
                    kubernetes.io/os=linux
                    node.kubernetes.io/instance-type=m5.large
                    topology.ebs.csi.aws.com/zone=eu-west-1c
                    topology.kubernetes.io/region=eu-west-1
                    topology.kubernetes.io/zone=eu-west-1c
                    workshop-default=no
                    tainted=yes    
[...]
```

## Cleanup 

The following commands can be used to the lab environment is cleaned up after the Taints module. 

1. Remove the configured taint on the tainted node group. Notice the `removeTaints` value passed to the `taints` parameter:

```bash
$ aws eks update-nodegroup-config \
    --cluster-name eks-workshop-cluster \
    --nodegroup-name managed-ondemand-tainted-20221103142426393800000006 \
    --taints "removeTaints=[{key=frontend, value=true, effect=NO_EXECUTE}]"
```
2. Restore the UI service to its default configuration

```bash
$ kubectl apply -k /workspace/manifests/ui
```