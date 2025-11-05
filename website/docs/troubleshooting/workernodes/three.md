---
title: "Node in Not-Ready state"
sidebar_position: 73
chapter: true
---

::required-time

### Background

Corporation XYZ's DevOps team has deployed a new node group and the application team deployed a new application outside of the retail-app, including a deployment (prod-app) and its supporting DaemonSet (prod-ds).

After deploying these applications, the monitoring team has reported that the node is transitioning to a **_NotReady_** state. The root cause isn't immediately apparent, and as the DevOps on-call engineer, you need to investigate why the node is becoming unresponsive and implement a solution to restore normal operation.

### Step 1: Verify Node Status

Let's first verify the node's status to confirm the current state:

```bash timeout=40 hook=fix-3-1 hookTimeout=60 wait=30
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3
NAME                                          STATUS     ROLES    AGE     VERSION
ip-10-42-180-244.us-west-2.compute.internal   NotReady   <none>   15m     v1.27.1-eks-2f008fe
```

### Step 2: Export Node Name

```bash
$ NODE_NAME=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 --no-headers | awk '{print $1}' | head -1)
```

### Step 3: Check System Pod Status

Let's examine the status of kube-system pods on the affected node to identify any system-level issues:

```bash
$ kubectl get pods -n kube-system -o wide --field-selector spec.nodeName=$NODE_NAME
```

This command will show us all kube-system pods running on the affected node, helping us identify any potential issues of the node caused by these. You should note that all the pods are in running state.

### Step 4: Examine Node Conditions

Let's examine the node's describe output to understand the cause of the _NotReady_ state.

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

Here we see that the Node's kubelet is in the _Unknown_ state and cannot be reached. You can read more about this status from the [Kubernetes documentation](https://kubernetes.io/docs/reference/node/node-status/#condition).

:::note Node Status Information
The node has the following taints:

- **node.kubernetes.io/unreachable:NoExecute**: Indicates pods will be evicted if they don't tolerate this taint
- **node.kubernetes.io/unreachable:NoSchedule**: Prevents new pods from being scheduled

The node conditions show that the kubelet has stopped posting status updates, which can typically indicate severe resource constraints or system instability.
:::

### Step 5: CloudWatch Metrics Investigation

Since Metrics Server isn't providing data, let's use CloudWatch to check EC2 instance metrics:

:::info
For your convenience, the instance ID of the worker node in new*nodegroup_3 has been stored as an environment variable *$INSTANCE*ID*.
:::

```bash
$ aws cloudwatch get-metric-data --region $AWS_REGION --start-time $(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ") --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") --metric-data-queries '[{"Id":"cpu","MetricStat":{"Metric":{"Namespace":"AWS/EC2","MetricName":"CPUUtilization","Dimensions":[{"Name":"InstanceId","Value":"'$INSTANCE_ID'"}]},"Period":60,"Stat":"Average"}}]'

{
    "MetricDataResults": [
        {
            "Id": "cpu",
            "Label": "CPUUtilization",
            "Timestamps": [
                "2025-0X-XXT16:25:00+00:00",
                "2025-0X-XXT16:20:00+00:00",
                "2025-0X-XXT16:15:00+00:00",
                "2025-0X-XXT16:10:00+00:00"
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

### Step 6: Mitigate Impact

Let's check deployment details and implement immediate changes to stabilize the node:

#### 6.1. Check the deployment resource configurations

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

#### 6.2. Let's scale down the deployment and stop the resource overload

```bash bash timeout=40 wait=25
$ kubectl scale deployment/prod-app -n prod --replicas=0 && kubectl delete pod -n prod -l app=prod-app --force --grace-period=0 && kubectl wait --for=delete pod -n prod -l app=prod-app
```

#### 6.3. Recycle the node on the nodegroup

```bash timeout=120 wait=95
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --scaling-config desiredSize=0 && \
aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 && \
aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --labels "addOrUpdateLabels={status=new-node}" && \
aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 && \
aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 --scaling-config desiredSize=1 && \
aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_3 && \
for i in {1..12}; do NODE_NAME_2=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3,status=new-node --no-headers -o custom-columns=":metadata.name" 2>/dev/null) && [ -n "$NODE_NAME_2" ] && break || sleep 5; done && \
[ -n "$NODE_NAME_2" ]
```

:::info
This can take up to a little over 1 minute. The script will store the new node name as NODE_NAME_2.
:::

#### 6.4. Verify node status

```bash test=false
$ kubectl get nodes --selector=kubernetes.io/hostname=$NODE_NAME_2
NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-42-180-24.us-west-2.compute.internal    Ready    <none>   0h43m   v1.30.8-eks-aeac579
```

### Step 7: Implementing Long-term Solutions

The Dev team has identified and fixed a memory leak in the application. Let's implement the fix and establish proper resource management:

#### 7.1. Apply the updated application configuration

```bash timeout=10 wait=5
$ kubectl apply -f /home/ec2-user/environment/eks-workshop/modules/troubleshooting/workernodes/yaml/configmaps-new.yaml
```

#### 7.2. Set resource limits for the deployment (cpu: 500m, memory: 512Mi)

```bash timeout=10 wait=5
$ kubectl patch deployment prod-app -n prod --patch '{"spec":{"template":{"spec":{"containers":[{"name":"prod-app","resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}}]}}}}'
```

#### 7.3. Set resource limits for the DaemonSet (cpu: 500m, memory: 512Mi)

```bash timeout=10 wait=5
$ kubectl patch daemonset prod-ds -n prod --patch '{"spec":{"template":{"spec":{"containers":[{"name":"prod-ds","resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}}]}}}}'
```

#### 7.4. Perform rolling updates and scale back to desired state

```bash timeout=20 wait=10
$ kubectl rollout restart deployment/prod-app -n prod && kubectl rollout restart daemonset/prod-ds -n prod && kubectl scale deployment prod-app -n prod --replicas=6
```

### Step 8: Verification

Let's verify our fixes have resolved the issues:

#### 8.1 Check pod creations

```bash test=false
$ kubectl get pods -n prod
NAME                        READY   STATUS    RESTARTS   AGE
prod-app-666f8f7bd5-658d6   1/1     Running   0          1m
prod-app-666f8f7bd5-6jrj4   1/1     Running   0          1m
prod-app-666f8f7bd5-9rf6m   1/1     Running   0          1m
prod-app-666f8f7bd5-pm545   1/1     Running   0          1m
prod-app-666f8f7bd5-ttkgs   1/1     Running   0          1m
prod-app-666f8f7bd5-zm8lx   1/1     Running   0          1m
prod-ds-ll4lv               1/1     Running   0          1m
```

#### 8.2. Check pod limits
```bash
$ kubectl get pods -n prod -o custom-columns="NAME:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEM_REQUEST:.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEM_LIMIT:.spec.containers[*].resources.limits.memory"
NAME                        CPU_REQUEST   MEM_REQUEST   CPU_LIMIT   MEM_LIMIT
prod-app-6d67889dc8-4hc7m   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-6s8wr   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-fd6kq   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-gzcbn   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-qvtvj   250m          256Mi         500m        512Mi
prod-app-6d67889dc8-rf478   250m          256Mi         500m        512Mi
prod-ds-srdqx               250m          256Mi         500m        512Mi
```

#### 8.3 Check node CPU resource
```bash wait=300 test=false
$ INSTANCE_ID=$(kubectl get node ${NODE_NAME_2} -o jsonpath='{.spec.providerID}' | cut -d '/' -f5) && aws cloudwatch get-metric-data --region $AWS_REGION --start-time $(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ") --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") --metric-data-queries '[{"Id":"cpu","MetricStat":{"Metric":{"Namespace":"AWS/EC2","MetricName":"CPUUtilization","Dimensions":[{"Name":"InstanceId","Value":"'$INSTANCE_ID'"}]},"Period":60,"Stat":"Average"}}]'
{
    "MetricDataResults": [
        {
            "Id": "cpu",
            "Label": "CPUUtilization",
            "Timestamps": [
                "2025-0X-XXT18:30:00+00:00",
                "2025-0X-XXT18:25:00+00:00"
            ],
            "Values": [
                88.05,
                58.63008430846801
            ],
            "StatusCode": "Complete"
        }
    ],
    "Messages": []
}
```
:::info
Check that CPU is not over utilized. 
:::
#### 8.4. Check node status

```bash
$ kubectl get node --selector=kubernetes.io/hostname=$NODE_NAME_2
NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-42-180-24.us-west-2.compute.internal    Ready    <none>   1h35m   v1.30.8-eks-aeac579
```

### Key Takeaways

#### 1. Resource Management

- Always set appropriate resource requests and limits
- Monitor cumulative workload impact
- Implement proper resource quotas

#### 2. Monitoring

- Use multiple monitoring tools
- Set up proactive alerting
- Monitor both container and node-level metrics

#### 3. Best Practices

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
