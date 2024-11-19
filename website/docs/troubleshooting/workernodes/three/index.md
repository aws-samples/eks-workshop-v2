---
title: "Node in Not-Ready state"
sidebar_position: 73
chapter: true
sidebar_custom_props: { "module": true }
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=700 wait=30
$ prepare-environment troubleshooting/workernodes/three
```

The preparation of the lab might take a little over five minutes and it will make the following changes to your lab environment:

- Create a new managed node group called **_new_nodegroup_3_**
- Introduce a problem to the managed node group which causes node to transition to the _NotReady_ state
- Set desired managed node group count to 1

:::

### Background

Corporate XYZ's e-commerce platform has been steadily growing, and the engineering team has decided to expand the EKS cluster to handle the increased workload. The team has already created a new managed node group **_new_nodegroup_3_**, and those have been successfully integrated into the cluster.

Now, the engineering team wants to ensure that the security and access control mechanisms are properly configured for the EKS cluster. They have assigned this task to Sam, an experienced DevOps engineer.

Sam's main objective is to grant a new admin user access to the EKS Cluster. So he makes modification to the aws-auth configmap, which is responsible for mapping IAM users and roles to Kubernetes RBAC permissions. The goal is to grant specific users additional permissions to access and manage the EKS cluster.

After making the changes to the AWS-Auth ConfigMap, the development team complains that they are not able to run any pods on the new managed nodegroup. Sam checks the Kubernetes events and logs, but does not find any obvious errors or issues. The EKS cluster status also appears to be healthy.

As time passes, Sam notices that the new worker node is transitioning to the **NotReady** state, indicating that they are unable to reach the cluster and participate in the workload.

Can you help Sam identify the root cause of the worker node issue and suggest the necessary steps to resolve the problem, so the new nodes can successfully join the EKS cluster?

### Step 1

1. First let's confirm and verify what you have learned from the engineer to see if there is a node in **NotReady** state.

```bash timeout=40 hook=fix-3-1 hookTimeout=60 wait=30
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3
NAME                                          STATUS     ROLES    AGE     VERSION
ip-10-42-174-208.us-west-2.compute.internal   NotReady   <none>   3m13s   v1.xx.x-eks-a737599
```

As you can see, we can confirm the node from _new_nodegroup_3_ is in NotReady state.

:::important
We will be gathering more information for this node throughout the scenario, so let's go ahead and add the node name as an environment variable. Please copy and paste the following in your terminal.

```bash
$ export NEW_NODEGROUP_3_NODE_NAME=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 | awk 'NR==2 {print $1}')

```

You can confirm variable the was taken.

```bash
$ echo $NEW_NODEGROUP_3_NODE_NAME
```

:::

### Step 2

First step after confirming node state is the check the node object itself. To check further into the node let's run a describe node and check for any signals pointing us more towards the problem.

:::info
**Note:** We have modified the describe command so it will output node Conditions, Allocated resources, and Events to minimize the output. Let's go through one at a time.
:::

First let's check the output for Node Conditions. This is where we can see statuses for each for the conditions. Towards the right-end under Reason and Message, we can see the reason for the _Unknown_ status is due to Kubelet stop posting node status.

```bash
$ kubectl describe node $NEW_NODEGROUP_3_NODE_NAME | sed -n '/Conditions:/,/Addresses:/p'

Conditions:
  Type             Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
  ----             ------    -----------------                 ------------------                ------              -------
  MemoryPressure   Unknown   Thu, 10 Oct 2024 17:00:39 +0000   Thu, 10 Oct 2024 17:01:22 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  DiskPressure     Unknown   Thu, 10 Oct 2024 17:00:39 +0000   Thu, 10 Oct 2024 17:01:22 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  PIDPressure      Unknown   Thu, 10 Oct 2024 17:00:39 +0000   Thu, 10 Oct 2024 17:01:22 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  Ready            Unknown   Thu, 10 Oct 2024 17:00:39 +0000   Thu, 10 Oct 2024 17:01:22 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
Addresses:
```

Next, we can check below, there are two pods (_vpc cni & kube-proxy_) running. They both have minimal CPU Requests configured and based on this it is unlikely that these pods are creating high resource utilizations.

```bash
$ kubectl describe node $NEW_NODEGROUP_3_NODE_NAME | sed -n '/Non-terminated Pods:/,/Events:/p'
Non-terminated Pods:          (2 in total)
  Namespace                   Name                CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                ------------  ----------  ---------------  -------------  ---
  kube-system                 aws-node-7f69d      50m (2%)      0 (0%)      0 (0%)           0 (0%)         34m
  kube-system                 kube-proxy-fxqmv    100m (5%)     0 (0%)      0 (0%)           0 (0%)         34m
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests   Limits
  --------           --------   ------
  cpu                150m (7%)  0 (0%)
  memory             0 (0%)     0 (0%)
  ephemeral-storage  0 (0%)     0 (0%)
  hugepages-1Gi      0 (0%)     0 (0%)
  hugepages-2Mi      0 (0%)     0 (0%)
Events:
```

Events are a common place to check to the latest messages logged during the lifecycle of a node. The takeaway from this particular output is that the kubelet transitioned into _NodeNotReady_.

```bash
$ kubectl describe node $NEW_NODEGROUP_3_NODE_NAME | sed -n '/Events:/,$p'
Events:
  Type     Reason                   Age                From                     Message
  ----     ------                   ----               ----                     -------
  Normal   Starting                 30m                kube-proxy
  Normal   Starting                 31m                kubelet                  Starting kubelet.
  Warning  InvalidDiskCapacity      31m                kubelet                  invalid capacity 0 on image filesystem
  Normal   NodeHasSufficientMemory  31m (x2 over 31m)  kubelet                  Node ip-10-42-174-208.us-west-2.compute.internal status is now: NodeHasSufficientMemory
  Normal   NodeHasNoDiskPressure    31m (x2 over 31m)  kubelet                  Node ip-10-42-174-208.us-west-2.compute.internal status is now: NodeHasNoDiskPressure
  Normal   NodeHasSufficientPID     31m (x2 over 31m)  kubelet                  Node ip-10-42-174-208.us-west-2.compute.internal status is now: NodeHasSufficientPID
  Normal   NodeAllocatableEnforced  31m                kubelet                  Updated Node Allocatable limit across pods
  Normal   Synced                   31m                cloud-node-controller    Node synced successfully
  Normal   RegisteredNode           30m                node-controller          Node ip-10-42-174-208.us-west-2.compute.internal event: Registered Node ip-10-42-174-208.us-west-2.compute.internal in Controller
  Normal   ControllerVersionNotice  30m                vpc-resource-controller  The node is managed by VPC resource controller version v1.4.10
  Normal   NodeReady                30m                kubelet                  Node ip-10-42-174-208.us-west-2.compute.internal status is now: NodeReady
  Normal   NodeNotReady             29m                node-controller          Node ip-10-42-174-208.us-west-2.compute.internal status is now: NodeNotReady
  Warning  Unsupported              29m (x9 over 30m)  vpc-resource-controller  The instance type t3.medium is not supported for trunk interface (Security Group for Pods)
```

Some important considerations when investigating node in _NotReady_ or _Unknown_ status is that this could be caused due to MemoryPressure, DiskcPressure, PIDPressure or any problem with the kubelet which can prevent it from sending heartbeats to the cluster's Control Plane. See the kubernetes [node-status document](https://kubernetes.io/docs/reference/node/node-status/#condition) for more details.

### Step 3

When a node start up, there are necessary components that must be running to ensure proper pod assigning and proper service network configurations deployed for proper traffic flow from and to the worker node. We can check these components by ensuring these pods are up and running. Let's check with kube-proxy first which is a network proxy that enables service abstraction and load balancing in a Kubernetes cluster.

```bash
$ kubectl get pods --namespace=kube-system --selector=k8s-app=kube-proxy -o wide | grep $NEW_NODEGROUP_3_NODE_NAME
kube-proxy-abcde   1/1     Running   0               127m    10.42.174.208   ip-10-42-174-208.us-west-2.compute.internal   <none>           <none>
```

Looks like it is in the 1/1 running state. Next we can check the vpc cni (aws-node pod) which is a networking plugin for Kubernetes that enables pod networking in Amazon VPC environments, allowing pods to have the same IP address inside the cluster as they do on the AWS VPC network.

```bash timeout=20 hook=fix-3-2 hookTimeout=25 wait=15
$ kubectl get pods --namespace=kube-system --selector=k8s-app=aws-node -o wide | grep $NEW_NODEGROUP_3_NODE_NAME
aws-node-7f69d   0/2     Pending   0               131m    10.42.174.208   ip-10-42-174-208.us-west-2.compute.internal   <none>           <none>
```

The aws-node pod is in the _Pending_ state so we need to figure out how to investigate further as to why.

:::important
We will be investigating further for this pod so please save the pod name as an environment variable. You can copy and paste the following in your terminal.

```bash
$ NEW_NODEGROUP_3_VPC_CNI_POD=$(kubectl get pods --namespace=kube-system --selector=k8s-app=aws-node --field-selector=spec.nodeName=$NEW_NODEGROUP_3_NODE_NAME -o jsonpath='{.items[0].metadata.name}')
```

You can confirm variable has taken.

```bash
$ echo $NEW_NODEGROUP_3_VPC_CNI_POD
```

:::

### Step 4

A pod in _Pending_ generally means that it has been accepted by the Kubernetes cluster, but one or more of the containers has not be set up and made ready to run. Many times this can be due to lack of node resources or time spend waiting for container image to download. More on Pod phases [here](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase).

Let's check the pod events to see if it has been scheduled.

```bash
$ kubectl describe pod $NEW_NODEGROUP_3_VPC_CNI_POD -n kube-system | sed -n '/Events:/,$p'
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  3m38s  default-scheduler  Successfully assigned kube-system/aws-node-xxxxx to ip-10-42-174-208.us-west-2.compute.internal
```

Looks like the pod has been scheduled successfully, but we saw that 0 out of the 2 containers start up successfully. So next we can check logs for the first container to see if we get any more insight.

```bash expectError=true
$ kubectl logs $NEW_NODEGROUP_3_VPC_CNI_POD -n kube-system aws-node
Error from server (InternalError): Internal error occurred: Authorization error (user=kube-apiserver-kubelet-client, verb=get, resource=nodes, subresource=proxy)
```

There is an internal error pointing to an Authorization error between the API server's kubelet client when initiating a GET call for the worker node resource. In order for proper communication from the Cluster's API server and the worker node to happen, proper authentication followed by authorization must occur from the worker node.

We know that our devops engineer was working with aws-auth configmap to add new users so lets check out how the configmap looks.

```bash
$ kubectl describe configmap aws-auth -n kube-system

Data
====
mapRoles:
----
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::1234567890:role/eksctl-eks-workshop-nodegroup-defa-NodeInstanceRole-1234abcd1234
  username: system:node:{{EC2PrivateDNSName}}
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::1234567890:role/xnew_nodegroup_3
  username: system:node:{{EC2PrivateDNSName}}

```

Looking closely at the node role arn, there appears to be a random string infront of new_nodegroup_3 (xnew_nodegroup_3). This does not look to belong there so let's confirm the node role name.

:::info
**Note:** _For your convenience we have added the Cluster name as env variable with the variable `$EKS_CLUSTER_NAME`._
:::

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new_nodegroup_3 --query 'nodegroup.nodeRole' --output text
arn:aws:iam::1234567890:role/new_nodegroup_3
```

As expected, we can see that the aws-auth configmap was modified. Please modify the aws-auth configmap properly without the 'x' string infront of the node name.

:::info
**Note:** The command below will modify the configmap by removing the 'x' infront of the role. Another way to modify is to run 'kubectl edit configmap aws-auth -n kube-system' command and make changes to the configmap resource directly.
:::

```bash
$ kubectl get configmap aws-auth -n kube-system -o yaml | sed 's/\(rolearn: arn:aws:iam::[0-9]*:role\/\)x\(.*\)/\1\2/' | kubectl apply -f -
```

Confirm that the configmap has been updated correctly and if it all looks good we can refresh the node.

```bash
$ kubectl describe configmap aws-auth -n kube-system
```

### Step 5

To refresh the node we can decrease the managed node group desired count to 0 and then back to 1. The script below will modify desiredSize to 0, wait for the nodegroup status to transition from InProgress to Active, then exit. This can take up to about 30 seconds.

```bash timeout=90 wait=60
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --scaling-config desiredSize=0; aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3; if [ $? -eq 0 ]; then echo "Node group scaled down to 0"; else echo "Failed to scale down node group"; exit 1; fi

{
    "update": {
        "id": "abcd1234-1234-abcd-1234-1234abcd1234",
        "status": "InProgress",
        "type": "ConfigUpdate",
        "params": [
            {
                "type": "DesiredSize",
                "value": "0"
            }
        ],
        "createdAt": "2024-10-23T16:56:03.522000+00:00",
        "errors": []
    }
}
Node group scaled down to 0
```

Once the above command is successful, you can set the desiredSize back to 1. This can take up to about 30 seconds.

```bash timeout=90 wait=60
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --scaling-config desiredSize=1 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3; if [ $? -eq 0 ]; then echo "Node group scaled up to 1"; else echo "Failed to scale up node group"; exit 1; fi

{
    "update": {
        "id": "abcd1234-1234-abcd-1234-1234abcd1234",
        "status": "InProgress",
        "type": "ConfigUpdate",
        "params": [
            {
                "type": "DesiredSize",
                "value": "1"
            }
        ],
        "createdAt": "2024-10-23T16:57:21.859000+00:00",
        "errors": []
    }
}
Node group scaled up to 1
```

If all goes well, you will see the new node join on the cluster after about up to one minute.

```bash timeout=100 wait=70
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-174-206.us-west-2.compute.internal   Ready   <none>   3m13s   v1.xx.x-eks-a737599
```

## Wrapping it up

In this scenario, the Devops engineer managed the cluster access for IAM users using aws-auth configmap. There are several benefits of using [Access Entries](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html) over modifying the aws-auth ConfigMap in Amazon EKS. To name a few, it provides higher level of security and efficiency by managing accessibility through EKS API. In this scenario, the engineer was managing user access manually by editing the aws-auth configmap which led to accidental unwanted entries to the configmap.

There are several other scenarios when it comes to nodes in the _NotReady_ or _Unknown_ status. We've covered checking the Node Conditions and aws-node/kube-proxy pods in this scenario which led to use identifying permissions related errors.

Aside from this, other factors that can lead to unknown status include:

- **Network reachability between control plane and worker nodes.** Our scenario brushed on this as communication was hindered due to permissions, however network related issues like SG, NACL or route table routeability between the two endpoints can also contribute.
- **Reachability to the EC2 API endpoint.** This is needed for the vpc cni to perform its needed operations to prepare ip addresses for pods.
- **Kubelet issues.** If kubelet encountered an issue it can prevent communication to the control plane. An example of when a kubelet can encounter issue is when customizing the worker node AMI/launchtemplate and modifies the kubelet or OS.

Please review the troubleshooting document [here](https://repost.aws/knowledge-center/eks-node-status-ready) to learn about troubleshooting nodes in the NotReady or Unknown status.
