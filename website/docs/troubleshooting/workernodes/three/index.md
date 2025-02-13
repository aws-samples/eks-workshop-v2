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
- Deploy resource kubernetes resources (deployment, daemonset, namespace, configmaps, priority-class)
- Set desired managed node group count to 1

:::

### Background

Corporation XYZ's DevOps team has deployed a new node group and the application team deployed a new version of their application, including a production application (prod-app) and its supporting DaemonSet (prod-ds).

After deploying their applications, the monitoring team has reported that the node is transitioning to a ***NotReady*** state. The root cause isn't immediately apparent, and as the DevOps on-call engineer, you need to investigate why the node is becoming unresponsive and implement a solution to restore normal operation.

### Step 1: Verify Node Status

Let's first verify the node's status to confirm the current state:

```bash timeout=40 hook=fix-3-1 hookTimeout=60 wait=30
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3
NAME                                          STATUS     ROLES    AGE     VERSION
ip-10-42-180-244.us-west-2.compute.internal   NotReady   <none>   15m     v1.27.1-eks-2f008fe
```


:::info
**Note:** For your convenience, we have added the node name as the environment variable $NODE_NAME. You can check this with:
```bash
$ echo $NODE_NAME
```
:::    


### Step 2: Check System Pod Status
Let's examine the status of kube-system pods on the affected node to identify any system-level issues:

```bash
$ kubectl get pods -n kube-system -o wide --field-selector spec.nodeName=$NODE_NAME
```
This command will show us all kube-system pods running on the affected node, helping us identify any potential issues of the node caused by these. You should note that all the pods are in running state.

### Step 3: Examine Node Conditions

Let's examine the node's describe output to understand the cause of the *NotReady* state.

```bash      
$ kubectl describe node $NODE_NAME | sed -n '/^Taints:/,/^[A-Z]/p;/^Conditions:/,/^[A-Z]/p;/^Events:/,$p'


Taints:             node.kubernetes.io/unreachable:NoExecute
                    node.kubernetes.io/unreachable:NoSchedule
Unschedulable:      false
Conditions:
  Type             Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
  ----             ------    -----------------                 ------------------                ------              -------
  MemoryPressure   Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  DiskPressure     Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  PIDPressure      Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  Ready            Unknown   Wed, 12 Feb 2025 15:20:21 +0000   Wed, 12 Feb 2025 15:21:04 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
Addresses:
Events:
  Type     Reason                   Age                    From                     Message
  ----     ------                   ----                   ----                     -------
  Normal   Starting                 3m18s                  kube-proxy               
  Normal   Starting                 3m31s                  kubelet                  Starting kubelet.
  Warning  InvalidDiskCapacity      3m31s                  kubelet                  invalid capacity 0 on image filesystem
  Normal   NodeHasSufficientMemory  3m31s (x2 over 3m31s)  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeHasSufficientMemory
  Normal   NodeHasNoDiskPressure    3m31s (x2 over 3m31s)  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeHasNoDiskPressure
  Normal   NodeHasSufficientPID     3m31s (x2 over 3m31s)  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeHasSufficientPID
  Normal   NodeAllocatableEnforced  3m31s                  kubelet                  Updated Node Allocatable limit across pods
  Normal   RegisteredNode           3m27s                  node-controller          Node ip-10-42-180-244.us-west-2.compute.internal event: Registered Node ip-10-42-180-244.us-west-2.compute.internal in Controller
  Normal   Synced                   3m27s                  cloud-node-controller    Node synced successfully
  Normal   ControllerVersionNotice  3m12s                  vpc-resource-controller  The node is managed by VPC resource controller version v1.6.3
  Normal   NodeReady                3m10s                  kubelet                  Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeReady
  Normal   NodeTrunkInitiated       3m8s                   vpc-resource-controller  The node has trunk interface initialized successfully
  Warning  SystemOOM                94s                    kubelet                  System OOM encountered, victim process: python, pid: 4763
  Normal   NodeNotReady             52s                    node-controller          Node ip-10-42-180-244.us-west-2.compute.internal status is now: NodeNotReady
```
Here we see that the Node's kubelet is in the *Unknown* state and cannot be reached. You can read more about this status from the [Kubernetes documentation](https://kubernetes.io/docs/reference/node/node-status/#condition).

:::note Node Status Information
The node has the following taints:

  - **node.kubernetes.io/unreachable:NoExecute**: Indicates pods will be evicted if they don't tolerate this taint
  - **node.kubernetes.io/unreachable:NoSchedule**: Prevents new pods from being scheduled

The node conditions show that the kubelet has stopped posting status updates, which can typically indicate severe resource constraints or system instability.
:::

### Step 4: Analyzing Resource Usage

Let's examine the resource utilization of our workloads using a monitoring tool. 

:::info
The metrics-server has already been installed in your cluster to provide resource usage data.
:::

1.  First, check node-level metrics:
```bash    
$ kubectl top nodes
NAME                                          CPU(cores)   CPU%        MEMORY(bytes)   MEMORY%     
ip-10-42-142-116.us-west-2.compute.internal   34m          1%          940Mi           13%         
ip-10-42-185-41.us-west-2.compute.internal    27m          1%          1071Mi          15%         
ip-10-42-96-176.us-west-2.compute.internal    175m         9%          2270Mi          32%         
ip-10-42-180-244.us-west-2.compute.internal   <unknown>    <unknown>   <unknown>       <unknown>  
```
2.  Next, attempt to check pod metrics:

```bash
$ kubectl top pods -n prod
error: Metrics not available for pod prod/prod-app-xx-xx, age: 17m14.466020856s
```
    
:::note
We can observe that:
  - The troubled node shows unknown for all metrics
  - Other nodes are operating normally with moderate resource usage
  - Pod metrics in the prod namespace are unavailable 
:::


### Step 5: CloudWatch Metrics Investigation

Since Metrics Server isn't providing data, let's use CloudWatch to check EC2 instance metrics:

:::info
For your convenience, the instance ID of the worker node in new_nodegroup_3 has been stored as an environment variable _$INSTANCE_ID_.
:::

```bash
$ aws cloudwatch get-metric-data --region us-west-2 --start-time $(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ") --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") --metric-data-queries '[{"Id":"cpu","MetricStat":{"Metric":{"Namespace":"AWS/EC2","MetricName":"CPUUtilization","Dimensions":[{"Name":"InstanceId","Value":"'$INSTANCE_ID'"}]},"Period":60,"Stat":"Average"}}]'

{
    "MetricDataResults": [
        {
            "Id": "cpu",
            "Label": "CPUUtilization",
            "Timestamps": [
                "2025-02-12T16:25:00+00:00",
                "2025-02-12T16:20:00+00:00",
                "2025-02-12T16:15:00+00:00",
                "2025-02-12T16:10:00+00:00"
            ],
            "Values": [
                99.87333333333333,
                99.89633636636336,
                99.86166666666668,
                62.67880324995537
            ],
            "StatusCode": "Complete"
        }
    ],
    "Messages": []
}
```
:::info
The CloudWatch metrics reveal:

  - CPU utilization consistently above 99%
  - Significant increase in resource usage over time
  - Clear indication of resource exhaustion 
:::


### Step 6: Implementing Immediate Fixes

Let's implement immediate fixes to stabilize the node:

1. Scale down the deployment to reduce load:

```bash   
$ kubectl scale deployment prod-app -n prod --replicas=1
```

:::note Node Recovery
If the node doesn't recover after scaling down, you may need to reboot the instance:
```bash test=false
$ aws ec2 reboot-instances --instance-ids $INSTANCE_IDS
```
Wait approximately 1 minute for the node to recover.
:::

2. Monitor node status:
```bash test=false
$ kubectl get nodes --selector=kubernetes.io/hostname=$NODE_NAME --watch
NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-42-180-244.us-west-2.compute.internal   Ready    <none>   0h43m   v1.30.8-eks-aeac579
```

3. Check resource configurations:


```bash
$ kubectl get pods -n prod -o custom-columns="NAME:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEM_REQUEST:.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEM_LIMIT:.spec.containers[*].resources.limits.memory"
NAME                        CPU_REQUEST   MEM_REQUEST   CPU_LIMIT   MEM_LIMIT
prod-app-74b97f9d85-k6c84   100m          64Mi          <none>      <none>
prod-app-74b97f9d85-mpcrv   100m          64Mi          <none>      <none>
prod-app-74b97f9d85-wdqlr   100m          64Mi          <none>      <none>
...
...
prod-ds-558sx               100m          128Mi         <none>      <none>
```

:::info
Notice that neither the deployment nor the DaemonSet has resource limits configured, which allowed unconstrained resource consumption.
:::

### Step 7: Implementing Long-term Solutions

The Dev team has identified and fixed a memory leak in the application. Let's implement the fix and establish proper resource management:

1. Apply the updated application configuration:

```bash timeout=10 wait=5
$ kubectl apply -f /home/ec2-user/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/configmaps-new.yaml
```

2. Set resource limits for the deployment:

```bash timeout=10 wait=5  
$ kubectl patch deployment prod-app -n prod --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "prod-app",
          "resources": {
            "limits": {
              "cpu": "500m",
              "memory": "512Mi"
            },
            "requests": {
              "cpu": "250m",
              "memory": "256Mi"
            }
          }
        }]
      }
    }
  }
}'
```

3. Set resource limits for the DaemonSet:

```bash timeout=10 wait=5
$ kubectl patch daemonset prod-d -n prod --patch '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "prod-app",
          "resources": {
            "limits": {
              "cpu": "500m",
              "memory": "512Mi"
            },
            "requests": {
              "cpu": "250m",
              "memory": "256Mi"
            }
          }
        }]
      }
    }
  }
}'
```
    

4. Perform rolling updates and scale back to desired state:


```bash timeout=20 wait=10
$ kubectl rollout restart deployment/prod-app -n prod && kubectl rollout restart daemonset/prod-ds -n prod && kubectl scale deployment prod-app -n prod --replicas=6
```

### Verification

Let's verify our fixes have resolved the issues:


1. Check node status
```bash
$ kubectl get node --selector=kubernetes.io/hostname=$NODE_NAME
NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-42-180-244.us-west-2.compute.internal   Ready    <none>   1h35m   v1.30.8-eks-aeac579     
```

:::note
If the node hasn't transitioned to Ready state, you may need to reboot it:
```bash test=false
$ aws ec2 reboot-instances --instance-ids $INSTANCE_IDS
```
:::

2. Verify pod resource usage
```bash
$ kubectl top pods -n prod
NAME                       CPU(cores)   MEMORY(bytes)   
prod-app-f8597858c-2n4fd   215m         425Mi           
prod-app-f8597858c-rrfdf   203m         426Mi           
prod-app-f8597858c-ssxxx   203m         426Mi           
prod-app-f8597858c-xhqd2   205m         425Mi           
prod-app-f8597858c-xppmg   248m         425Mi           
prod-app-f8597858c-zh46j   215m         425Mi           
prod-ds-x59km              586m         3Mi  
```

3. Check node resource usage
```bash
$ kubectl top node --selector=kubernetes.io/hostname=$NODE_NAME   
NAME                                          CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
ip-10-42-180-244.us-west-2.compute.internal   1612m        83%    3145Mi          44%  
```

### Key Takeaways

  1. Resource Management
      - Always set appropriate resource requests and limits
      - Monitor cumulative workload impact
      - Implement proper resource quotas

  2. Monitoring
      - Use multiple monitoring tools
      - Set up proactive alerting
      - Monitor both container and node-level metrics

  3. Best Practices
      - Implement horizontal pod autoscaling
      - Use autoscaling: [Cluster-autoscaler](https://docs.aws.amazon.com/eks/latest/best-practices/cas.html), [Karpenter](https://docs.aws.amazon.com/eks/latest/best-practices/karpenter.html), [EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html)
      - Regular capacity planning
      - Implement proper error handling in applications

### Additional Resources

  - [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
  - [Out of Resource Handling](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/)
  - [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
  - [Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-metrics-EKS.html)
  - [Knowledge Center Guide](https://repost.aws/knowledge-center/eks-node-status-ready)

