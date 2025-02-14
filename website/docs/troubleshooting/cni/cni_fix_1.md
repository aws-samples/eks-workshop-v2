---
title: "Fixing Addons Configuration Issue OLD"
sidebar_position: 41
---

In this hands-on troubleshooting exercise, you will explore the EKS Managed Addons for AWS VPC CNI and examine the cluster's nodes and pods. You'll follow a guided script that will lead you through the investigation process step by step. By the end of this session, your goal is to ensure that the nginx-app in your EKS cluster is successfully running. This practical scenario will help you develop essential skills for managing and troubleshooting Kubernetes deployments on Amazon EKS.

## Let's start the troubleshooting

### Step 1

Let's begin by checking the current state of our Kubernetes environment. We'll use the command-line tool kubectl to examine the status of our pods and nodes. This step is crucial for understanding our cluster's health and readiness before proceeding with further operations.

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

When examining the pod status, we observe that they are in a Pending state. A Pod in Pending status indicates that it cannot be assigned to a node for execution. This situation typically arises due to a lack of necessary resources, preventing proper scheduling. we'll select a representative pod name as our focus

```bash
$ export POD_NAME=$(kubectl get pods -n cni-tshoot -o custom-columns=:metadata.name --no-headers | awk 'NR==1{print $1}')
```

:::info
In our specific scenario, we have configured our pod to be allocated to a newly created managed nodegroup called **cni_troubleshooting**. This allocation is controlled through the use of node affinity rules, as well as taints and tolerations, which are advanced Kubernetes scheduling features.
:::

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
  namespace: cni-tshoot
  labels:
    app: nginx
spec:
  replicas: 15
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
    // highlight-start
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: app
                operator: In
                values:
                - cni_troubleshooting
    // highlight-end
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
      // highlight-start
      tolerations:
      - key: "purpose"
        operator: "Exists"
        effect: "NoSchedule"
      // highlight-end
```

To troubleshoot pods that are stuck in a Pending state, we can use the 'describe' command to obtain detailed information about their current status and any potential issues preventing them from running.

```bash test=false
$ kubectl describe pod -n cni-tshoot $POD_NAME

Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  29s   default-scheduler  0/4 nodes are available: 1 node(s) had untolerated taint {node.kubernetes.io/not-ready: }, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
```

Analyzing this output, we can conclude that the pod scheduling was unsuccessful due to the lack of suitable nodes in the cluster. The information reveals that the cluster consists of four nodes. One of these nodes is in a NotReady state, while the remaining three nodes are unable to accommodate the pod due to node affinity requirements not being met. This situation highlights the importance of proper resource allocation and node affinity configuration in Kubernetes clusters.

### Step 2

The pod's node affinity settings from Step 1 indicate a preference for nodes labeled with 'app=cni_troubleshooting'. To proceed with our troubleshooting process, let's examine the status of nodes carrying this specific label. This step will help us understand where these pods are likely to be scheduled and identify any potential issues with node availability or labeling.

```bash
$ kubectl get nodes -l app=cni_troubleshooting -L app
NAME                                         STATUS    ROLES    AGE   VERSION               APP
ip-10-42-117-53.us-west-2.compute.internal   NotReady  <none>   91s   v1.30.0-eks-036c24b   cni_troubleshooting
```

we'll select this node as our focus

```bash test=false
$ export NODE_NAME=$(kubectl get nodes -l app=cni_troubleshooting -L app -o custom-columns=:metadata.name --no-headers)
```

Now, let's investigate the reason behind this node's NotReady state. We'll use the describe command to gather detailed information about the node, paying particular attention to the Conditions section in the output. This will help us identify the specific issues preventing the node from being ready. Take a moment to run the command and analyze the results

```bash test=false
$ kubectl describe node $NODE_NAME

Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Wed, 30 Oct 2024 19:37:02 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Wed, 30 Oct 2024 19:37:02 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Wed, 30 Oct 2024 19:37:02 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Wed, 30 Oct 2024 19:37:02 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
```

Let's analyze the situation: The node was in a NotReady state because the CNI (Container Network Interface) plugin wasn't initialized.

:::info
On EKS Linux nodes, the CNI plugin is initialized by a healthy VPC CNI pod called 'aws-node'. These aws-node pods run as DaemonSets, meaning each Linux worker node should have one.
:::

Action step: Review the 'Non-terminated Pods' section in the describe node output. Look for an aws-node pod on this specific node. If it's missing or in an unhealthy state, this could explain the NotReady status.

```bash test=false
$ kubectl describe node $NODE_NAME

Non-terminated Pods:          (2 in total)
  Namespace                   Name                         CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                         ------------  ----------  ---------------  -------------  ---
  kube-system                 kube-proxy-69754             100m (5%)     0 (0%)      0 (0%)           0 (0%)         17m
```

Is the aws-node pod present and healthy? If not, what would be your next steps to troubleshoot or resolve this issue?

### Step 3

Having identified that the aws-node is missing from the node, our next step is to investigate the aws-node daemonset. Let's use the kubectl describe command to gather more information about this daemonset and understand why it's not running on the affected node. This will help us pinpoint the root cause of the issue and determine the appropriate solution.

```bash test=false
$ kubectl describe ds aws-node -n kube-system
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

The DaemonSet appears to be functioning correctly, as the Desired and Current pod numbers match the cluster's node count. However, we've identified one pod in a waiting state. Let's investigate further by examining the status of all aws-node pods in the cluster. This will help us pinpoint the cause of the waiting pod

```bash
$ kubectl get pods -n kube-system -l k8s-app=aws-node -o wide
NAME             READY   STATUS    RESTARTS   AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
aws-node-5fgqh   2/2     Running   0          72m   10.42.165.112   ip-10-42-165-112.us-west-2.compute.internal   <none>           <none>
aws-node-mkjkr   0/2     Pending   0          20m   <none>          <none>                                        <none>           <none>
aws-node-shw94   2/2     Running   0          72m   10.42.145.11    ip-10-42-145-11.us-west-2.compute.internal    <none>           <none>
aws-node-v9dq6   2/2     Running   0          72m   10.42.102.141   ip-10-42-102-141.us-west-2.compute.internal   <none>           <none>
```

Let's select the Pending aws-node pod

```bash
$ export AWS_NODE_POD=$(kubectl get pods -l k8s-app=aws-node -n kube-system | grep Pending | awk 'NR==1{print $1}')
```

An aws-node pod is currently in a Pending state, which is unusual for this critical system daemonset. Normally, aws-node should run even on NotReady nodes. Let's investigate further by describing the affected pod to identify the root cause of this issue.

```bash
$ kubectl describe pod -n kube-system $AWS_NODE_POD
Name:                 aws-node-mkjkr
Namespace:            kube-system
Priority:             2000001000
Priority Class Name:  system-node-critical
Service Account:      aws-node
Node:                 <none>
Labels:               app.kubernetes.io/instance=aws-vpc-cni
                      app.kubernetes.io/name=aws-node
                      controller-revision-hash=774956ddb4
                      k8s-app=aws-node
                      pod-template-generation=5
Annotations:          <none>
Status:               Pending
IP:
IPs:                  <none>
Controlled By:        DaemonSet/aws-node
Init Containers:
  aws-vpc-cni-init:
    Image:      602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon-k8s-cni-init:v1.16.0-eksbuild.1
    Port:       <none>
    Host Port:  <none>
    Requests:
      cpu:     25m
      memory:  2G
    Environment:
      DISABLE_TCP_EARLY_DEMUX:      false
      ENABLE_IPv6:                  false
      AWS_STS_REGIONAL_ENDPOINTS:   regional
      AWS_DEFAULT_REGION:           us-west-2
      AWS_REGION:                   us-west-2
      AWS_ROLE_ARN:                 arn:aws:iam::1234567890:role/eksctl-eks-workshop-addon-vpc-cni-Role1-rvDMIG8AaPGr
      AWS_WEB_IDENTITY_TOKEN_FILE:  /var/run/secrets/eks.amazonaws.com/serviceaccount/token
    Mounts:
      /host/opt/cni/bin from cni-bin-dir (rw)
      /var/run/secrets/eks.amazonaws.com/serviceaccount from aws-iam-token (ro)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2npz9 (ro)
Containers:
  aws-node:
    Image:      602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon-k8s-cni:v1.16.0-eksbuild.1
    Port:       61678/TCP
    Host Port:  61678/TCP
    Requests:
      cpu:      25m
      memory:   2G
    Liveness:   exec [/app/grpc-health-probe -addr=:50051 -connect-timeout=5s -rpc-timeout=5s] delay=60s timeout=10s period=10s #success=1 #failure=3
    Readiness:  exec [/app/grpc-health-probe -addr=:50051 -connect-timeout=5s -rpc-timeout=5s] delay=1s timeout=10s period=10s #success=1 #failure=3
    Environment:
      ADDITIONAL_ENI_TAGS:                    {}
      ANNOTATE_POD_IP:                        false
      AWS_VPC_CNI_NODE_PORT_SUPPORT:          true
      AWS_VPC_ENI_MTU:                        9001
      AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG:     false
      AWS_VPC_K8S_CNI_EXTERNALSNAT:           false
      AWS_VPC_K8S_CNI_LOGLEVEL:               DEBUG
      AWS_VPC_K8S_CNI_LOG_FILE:               /host/var/log/aws-routed-eni/ipamd.log
      AWS_VPC_K8S_CNI_RANDOMIZESNAT:          prng
      AWS_VPC_K8S_CNI_VETHPREFIX:             eni
      AWS_VPC_K8S_PLUGIN_LOG_FILE:            /var/log/aws-routed-eni/plugin.log
      AWS_VPC_K8S_PLUGIN_LOG_LEVEL:           DEBUG
      CLUSTER_NAME:                           eks-workshop
      DISABLE_INTROSPECTION:                  false
      DISABLE_METRICS:                        false
      DISABLE_NETWORK_RESOURCE_PROVISIONING:  false
      ENABLE_IPv4:                            true
      ENABLE_IPv6:                            false
      ENABLE_POD_ENI:                         true
      ENABLE_PREFIX_DELEGATION:               true
      POD_SECURITY_GROUP_ENFORCING_MODE:      standard
      VPC_CNI_VERSION:                        v1.16.0
      VPC_ID:                                 vpc-0be3747f7a6076d7c
      WARM_ENI_TARGET:                        1
      WARM_PREFIX_TARGET:                     1
      MY_NODE_NAME:                            (v1:spec.nodeName)
      MY_POD_NAME:                            aws-node-mkjkr (v1:metadata.name)
      AWS_STS_REGIONAL_ENDPOINTS:             regional
      AWS_DEFAULT_REGION:                     us-west-2
      AWS_REGION:                             us-west-2
      AWS_ROLE_ARN:                           arn:aws:iam::1234567890:role/eksctl-eks-workshop-addon-vpc-cni-Role1-rvDMIG8AaPGr
      AWS_WEB_IDENTITY_TOKEN_FILE:            /var/run/secrets/eks.amazonaws.com/serviceaccount/token
    Mounts:
      /host/etc/cni/net.d from cni-net-dir (rw)
      /host/opt/cni/bin from cni-bin-dir (rw)
      /host/var/log/aws-routed-eni from log-dir (rw)
      /run/xtables.lock from xtables-lock (rw)
      /var/run/aws-node from run-dir (rw)
      /var/run/secrets/eks.amazonaws.com/serviceaccount from aws-iam-token (ro)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2npz9 (ro)
  aws-eks-nodeagent:
    Image:      602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-network-policy-agent:v1.0.7-eksbuild.1
    Port:       <none>
    Host Port:  <none>
    Args:
      --enable-ipv6=false
      --enable-network-policy=true
      --enable-cloudwatch-logs=false
      --enable-policy-event-logs=true
      --metrics-bind-addr=:8162
      --health-probe-bind-addr=:8163
      --conntrack-cache-cleanup-period=300
    Requests:
      cpu:     25m
      memory:  2G
    Environment:
      MY_NODE_NAME:                  (v1:spec.nodeName)
      AWS_STS_REGIONAL_ENDPOINTS:   regional
      AWS_DEFAULT_REGION:           us-west-2
      AWS_REGION:                   us-west-2
      AWS_ROLE_ARN:                 arn:aws:iam::1234567890:role/eksctl-eks-workshop-addon-vpc-cni-Role1-rvDMIG8AaPGr
      AWS_WEB_IDENTITY_TOKEN_FILE:  /var/run/secrets/eks.amazonaws.com/serviceaccount/token
    Mounts:
      /host/opt/cni/bin from cni-bin-dir (rw)
      /sys/fs/bpf from bpf-pin-path (rw)
      /var/log/aws-routed-eni from log-dir (rw)
      /var/run/aws-node from run-dir (rw)
      /var/run/secrets/eks.amazonaws.com/serviceaccount from aws-iam-token (ro)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-2npz9 (ro)
Conditions:
  Type           Status
  PodScheduled   False
Volumes:
  aws-iam-token:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  86400
  bpf-pin-path:
    Type:          HostPath (bare host directory volume)
    Path:          /sys/fs/bpf
    HostPathType:
  cni-bin-dir:
    Type:          HostPath (bare host directory volume)
    Path:          /opt/cni/bin
    HostPathType:
  cni-net-dir:
    Type:          HostPath (bare host directory volume)
    Path:          /etc/cni/net.d
    HostPathType:
  log-dir:
    Type:          HostPath (bare host directory volume)
    Path:          /var/log/aws-routed-eni
    HostPathType:  DirectoryOrCreate
  run-dir:
    Type:          HostPath (bare host directory volume)
    Path:          /var/run/aws-node
    HostPathType:  DirectoryOrCreate
  xtables-lock:
    Type:          HostPath (bare host directory volume)
    Path:          /run/xtables.lock
    HostPathType:
  kube-api-access-2npz9:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 op=Exists
                             node.kubernetes.io/disk-pressure:NoSchedule op=Exists
                             node.kubernetes.io/memory-pressure:NoSchedule op=Exists
                             node.kubernetes.io/network-unavailable:NoSchedule op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists
                             node.kubernetes.io/pid-pressure:NoSchedule op=Exists
                             node.kubernetes.io/unreachable:NoExecute op=Exists
                             node.kubernetes.io/unschedulable:NoSchedule op=Exists
Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  3m15s (x5 over 14m)  default-scheduler  0/4 nodes are available: 1 Insufficient memory. preemption: 0/4 nodes are available: 1 Insufficient memory, 3 Preemption is not helpful for scheduling.
```

The issue stems from insufficient memory on one of the nodes to meet the aws-node pod's 4 GB memory request. To resolve this, we have two options:

1. Create a new nodegroup with more resources
2. Adjust the memory request for the aws-node daemonset

We'll proceed with option 2. Since the aws-node daemonset is deployed via Amazon VPC CNI managed addons, let's examine the addon configuration.

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

### Step 4

Having identified the necessary VPC CNI configuration adjustments for aws-node compatibility, let's proceed to update our setup.

First, remove the existing resource definitions and create a variable with the revised configuration

```bash
$ export CURRENT_CONFIG=$(aws eks describe-addon --addon-name vpc-cni --cluster-name $EKS_CLUSTER_NAME --output text --query addon.configurationValues)
$ export REVISED_CONFIG=$(echo $CURRENT_CONFIG | jq -c 'del(.resources)')
```

Then maintain IRSA Configuration for VPC CNI Add-ons: When updating the configuration of VPC CNI managed add-ons, it's crucial to preserve the existing IAM Role for Service Account (IRSA) setup. Before making any changes, identify the associated IAM role to ensure it remains intact throughout the update process

```bash
$ export CNI_ROLE_ARN=$(aws eks describe-addon --addon-name vpc-cni --cluster-name $EKS_CLUSTER_NAME --output text --query addon.serviceAccountRoleArn)
```

Now, apply the configuration changes using `aws eks update-addon` CLI command

```bash timeout=180 hook=fix-1 hookTimeout=600
$ aws eks update-addon --addon-name vpc-cni --cluster-name $EKS_CLUSTER_NAME --service-account-role-arn $CNI_ROLE_ARN --configuration-values $REVISED_CONFIG
```

After completing the update process, verify that aws-node pods are now scheduled on all worker nodes. Check the pod distribution to ensure proper deployment across the cluster.

```bash
$ kubectl get pods -n kube-system -l k8s-app=aws-node -o wide
NAME             READY   STATUS    RESTARTS   AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
aws-node-5fgqh   2/2     Running   0          83m   10.42.165.112   ip-10-42-165-112.us-west-2.compute.internal   <none>           <none>
aws-node-5jwzn   1/2     Running   0          32s   100.64.3.8      ip-100-64-3-8.us-west-2.compute.internal      <none>           <none>
aws-node-v9dq6   2/2     Running   0          83m   10.42.102.141   ip-10-42-102-141.us-west-2.compute.internal   <none>           <none>
aws-node-zwxhf   1/2     Running   0          31s   10.42.145.11    ip-10-42-145-11.us-west-2.compute.internal    <none>           <none>
```
