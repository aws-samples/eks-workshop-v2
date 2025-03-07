---
title: "Fixing VPC CNI Addon Configuration"
sidebar_position: 41
---

In this hands-on troubleshooting exercise, you will investigate an issue with the AWS VPC CNI plugin in an Amazon EKS cluster. You'll follow a step-by-step process to identify why pods are not scheduling correctly and implement a solution. By the end of this session, you'll ensure that the VPC CNI is configured properly for the nginx-app.

## Let's start the troubleshooting

### Step 1: Assess the Current State

#### 1.1. Begin by examining the status of pods in the cni-tshoot namespace

```bash
$ kubectl get pods -n cni-tshoot
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-5cf4cbfd97-58xkz   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-87zjw   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-8z8vh   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-8zcjq   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-9c5mb   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-bp9xs   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-d4bbt   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-g56hj   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-jjxsv   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-lvp92   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-n8rmx   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-q59d5   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-qnhjg   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-vj6nn   0/1     Pending   0          11m
nginx-app-5cf4cbfd97-wrr2c   0/1     Pending   0          11m
```

We observe that all pods are in a Pending state. Let's select a representative pod for further investigation:

```bash
$ export POD_NAME=$(kubectl get pods -n cni-tshoot -o custom-columns=:metadata.name --no-headers | awk 'NR==1{print $1}')
```

:::info 
In this scenario, pods are configured to be allocated to a newly created managed nodegroup called cni_troubleshooting using node affinity rules, taints, and tolerations.

:::

#### 1.2. Investigate the pod's scheduling issues

```bash test=false
$ kubectl describe pod -n cni-tshoot $POD_NAME | sed -n '/^Events:/,$ p'

Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  29s   default-scheduler  0/4 nodes are available: 1 node(s) had untolerated taint {node.kubernetes.io/not-ready: }, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

The output indicates that pod scheduling failed due to node affinity requirements and taints. There is an untolerated taint for *node.kubernetes.io/not-ready*.

### Step 2: Examine Node Status

#### 2.1 Check the status of the node from cni_troubleshooting nodegroup


```bash
$ kubectl get nodes -l app=cni_troubleshooting -L app
NAME                                         STATUS    ROLES    AGE   VERSION               APP
ip-10-42-117-53.us-west-2.compute.internal   NotReady  <none>   91s   v1.30.0-eks-036c24b   cni_troubleshooting
```

#### 2.2 Select this node for further investigation

```bash test=false
$ export NODE_NAME=$(kubectl get nodes -l app=cni_troubleshooting -L app -o custom-columns=:metadata.name --no-headers)
```

#### 2.3. Examine the node's condition

```bash test=false
$ kubectl describe node $NODE_NAME | sed -n '/^Conditions:/,/^Addresses:/ p' | head -n -1
...
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Wed, 30 Oct 2024 19:37:02 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Wed, 30 Oct 2024 19:37:02 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Wed, 30 Oct 2024 19:37:02 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Wed, 30 Oct 2024 19:37:02 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
```

The output reveals that the node is NotReady due to the CNI plugin not being initialized.
:::info
On EKS Linux nodes, the CNI plugin is initialized by a healthy VPC CNI pod called 'aws-node'. These aws-node pods run as DaemonSets, meaning each Linux worker node should have one. This is missing for this node: 

```bash test=false
$ kubectl describe node $NODE_NAME | sed -n '/^Non-terminated Pods:/,/^Allocated resources:/ p' | head -n -1
...
Non-terminated Pods:          (2 in total)
  Namespace                   Name                         CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                         ------------  ----------  ---------------  -------------  ---
  kube-system                 kube-proxy-69754             100m (5%)     0 (0%)      0 (0%)           0 (0%)         17m
```
:::

### Step 3: Investigate the AWS VPC CNI DaemonSet

#### 3.1. Examine the aws-node DaemonSet

```bash test=false
$ kubectl describe ds aws-node -n kube-system | sed -n '/^Name:/,/^Pods Status:/ p'
Name:           aws-node
Selector:       k8s-app=aws-node
Node-Selector:  <none>
Labels:         app.kubernetes.io/instance=aws-vpc-cni
                app.kubernetes.io/managed-by=Helm
                app.kubernetes.io/name=aws-node
                app.kubernetes.io/version=v1.16.0
                helm.sh/chart=aws-vpc-cni-1.16.0
                k8s-app=aws-node
Annotations:    deprecated.daemonset.template.generation: 5
Desired Number of Nodes Scheduled: 4
Current Number of Nodes Scheduled: 4
Number of Nodes Scheduled with Up-to-date Pods: 4
Number of Nodes Scheduled with Available Pods: 3
Number of Nodes Misscheduled: 0
Pods Status:  3 Running / 1 Waiting / 0 Succeeded / 0 Failed
```
:::info
One DaemonSet pod is in a waiting state.
:::

#### 3.2. Check the status of aws-node pods

```bash
$ kubectl get pods -n kube-system -l k8s-app=aws-node -o wide
NAME             READY   STATUS    RESTARTS   AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
aws-node-5fgqh   2/2     Running   0          72m   10.42.165.112   ip-10-42-165-112.us-west-2.compute.internal   <none>           <none>
aws-node-mkjkr   0/2     Pending   0          20m   <none>          <none>                                        <none>           <none>
aws-node-shw94   2/2     Running   0          72m   10.42.145.11    ip-10-42-145-11.us-west-2.compute.internal    <none>           <none>
aws-node-v9dq6   2/2     Running   0          72m   10.42.102.141   ip-10-42-102-141.us-west-2.compute.internal   <none>           <none>
```

#### 3.3. Investigate the Pending aws-node pod


Let's select the Pending aws-node pod.
```bash
$ export AWS_NODE_POD=$(kubectl get pods -l k8s-app=aws-node -n kube-system | grep Pending | awk 'NR==1{print $1}')
```

Then describe the pod.
```bash
$ kubectl describe pod -n kube-system $AWS_NODE_POD | sed -n '/^Events:/,$ p'

Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  3m15s (x5 over 14m)  default-scheduler  0/4 nodes are available: 1 Insufficient memory. preemption: 0/4 nodes are available: 1 Insufficient memory, 3 Preemption is not helpful for scheduling.
```

The output shows that the aws-node pod is failing to schedule due to insufficient memory.

### Step 4: Adjust VPC CNI Configuration

#### 4.1. Examine the current VPC CNI addon configuration

```bash test=false
$ aws eks describe-addon --addon-name vpc-cni --cluster-name $EKS_CLUSTER_NAME --output text --query addon.configurationValues | jq .
{
  "env": {
    "ENABLE_PREFIX_DELEGATION": "true",
    "ENABLE_POD_ENI": "true",
    "POD_SECURITY_GROUP_ENFORCING_MODE": "standard"
  },
  "enableNetworkPolicy": "true",
  "nodeAgent": {
    "enablePolicyEventLogs": "true"
  },
  "resources": {
    "requests": {
      "memory": "2G"
    }
  }
}
```
:::info
Resources is configured with request of 2G memory.
:::
#### 4.2. Prepare the revised configuration

Let's export the current config followed by the revised config.
```bash
$ export CURRENT_CONFIG=$(aws eks describe-addon --addon-name vpc-cni --cluster-name $EKS_CLUSTER_NAME --output text --query addon.configurationValues) && echo $CURRENT_CONFIG 

{"env":{"ENABLE_PREFIX_DELEGATION":"true","ENABLE_POD_ENI":"true","POD_SECURITY_GROUP_ENFORCING_MODE":"standard"},"enableNetworkPolicy":"true","nodeAgent":{"enablePolicyEventLogs":"true"},"resources":{"requests":{"memory":"2G"}}}
```
```bash
$ export REVISED_CONFIG=$(echo $CURRENT_CONFIG | jq -c 'del(.resources)') && echo $REVISED_CONFIG

{"env":{"ENABLE_PREFIX_DELEGATION":"true","ENABLE_POD_ENI":"true","POD_SECURITY_GROUP_ENFORCING_MODE":"standard"},"enableNetworkPolicy":"true","nodeAgent":{"enablePolicyEventLogs":"true"}}
```

#### 4.3. Preserve the IRSA configuration

Store the service account ARN.

```bash
$ export CNI_ROLE_ARN=$(aws eks describe-addon --addon-name vpc-cni --cluster-name $EKS_CLUSTER_NAME --output text --query addon.serviceAccountRoleArn)
```

#### 4.4. Apply the addon configuration changes

```bash timeout=180 hook=fix-1 hookTimeout=600
$ aws eks update-addon --addon-name vpc-cni --cluster-name $EKS_CLUSTER_NAME --service-account-role-arn $CNI_ROLE_ARN --configuration-values $REVISED_CONFIG
```

### Step 5: Verify the Fix

#### 5.1. Check that aws-node pods are now scheduled on all worker nodes

```bash
$ kubectl get pods -n kube-system -l k8s-app=aws-node -o wide
NAME             READY   STATUS    RESTARTS   AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
aws-node-5fgqh   2/2     Running   0          83m   10.42.165.112   ip-10-42-165-112.us-west-2.compute.internal   <none>           <none>
aws-node-5jwzn   1/2     Running   0          32s   100.64.3.8      ip-100-64-3-8.us-west-2.compute.internal      <none>           <none>
aws-node-v9dq6   2/2     Running   0          83m   10.42.102.141   ip-10-42-102-141.us-west-2.compute.internal   <none>           <none>
aws-node-zwxhf   1/2     Running   0          31s   10.42.145.11    ip-10-42-145-11.us-west-2.compute.internal    <none>           <none>
```



### Conclusion

In this troubleshooting exercise, we identified and resolved a configuration issue with the AWS VPC CNI addon that was preventing pods from scheduling correctly. Here's a summary of what we learned:

#### Problem Identification:
- The nginx-app pods were stuck in Pending state
- The aws-node pod was failing to schedule due to insufficient memory
- The VPC CNI addon configuration had excessive memory requests

#### Root Cause:
- The VPC CNI addon configuration included high memory requests
- This prevented the aws-node DaemonSet from scheduling on nodes with limited resources

#### Resolution Steps:
- We examined the current VPC CNI addon configuration
- Prepared a revised configuration without the excessive resource requests
- Applied the updated configuration while preserving the IRSA setup
- Verified that aws-node pods were successfully scheduled on all worker nodes

#### Key Takeaways:
- Carefully review and adjust addon configurations, especially resource requests
- Consider the impact of DaemonSet resource requests on node capacity
- Monitor the status of critical system pods like aws-node
- Use AWS CLI to manage EKS addon configurations effectively

### Additional Resources

- [Amazon EKS VPC CNI Documentation](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html)
- [Kubernetes DaemonSet Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Amazon EKS Add-ons](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)
