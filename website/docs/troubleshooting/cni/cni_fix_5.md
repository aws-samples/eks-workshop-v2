---
title: "Fixing Policy Issue"
sidebar_position: 42
---

### Step 5

Well done on scheduling aws-node on all worker nodes! Now, let's tackle our main objective: getting the nginx-app pods running. They're currently still stuck in Pending status. Your next task is to investigate the cause and implement a solution to achieve full cluster functionality. Ready to continue troubleshooting?

```bash
$ kubectl get pods -n cni-tshoot
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-5cf4cbfd97-2v8tp   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-5nw9n   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-9vf6k   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-bmtb2   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-d9wcn   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-lplnw   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-n2whf   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-pxf57   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-sb4fm   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-spv2b   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-v2xp2   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-vllxz   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-wbvtv   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-wm7xd   0/1     Pending   0          16m
nginx-app-5cf4cbfd97-wn9lc   0/1     Pending   0          16m
```

```bash
$ kubectl get nodes -L app
NAME                                          STATUS     ROLES    AGE    VERSION               APP
ip-10-42-102-141.us-west-2.compute.internal   Ready      <none>   160m   v1.30.0-eks-036c24b
ip-10-42-145-11.us-west-2.compute.internal    Ready      <none>   160m   v1.30.0-eks-036c24b
ip-10-42-165-112.us-west-2.compute.internal   Ready      <none>   160m   v1.30.0-eks-036c24b
ip-100-64-3-8.us-west-2.compute.internal      NotReady   <none>   82m    v1.30.4-eks-a737599   cni_troubleshooting
```

Despite the aws-node being scheduled, the worker nodes remain in a NotReady state. Let's investigate further by describing the node again to assess its current status.

```bash test=false
$ kubectl describe node $NODE_NAME | grep Conditions: -A 7
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Wed, 30 Oct 2024 20:43:45 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Wed, 30 Oct 2024 20:43:45 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Wed, 30 Oct 2024 20:43:45 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Wed, 30 Oct 2024 20:43:45 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
```

:::info
To ensure EKS worker nodes become Ready when using the default AWS VPC CNI, all containers in the aws-node pod must be ready
:::
Let's identify the aws-node pod on this node:

1. Examine the Non-terminated Pods section in the output.
2. Locate the pod name starting with 'aws-node'.

This step is crucial for troubleshooting node readiness issues."

```bash test=false
$ kubectl describe node $NODE_NAME | grep Non-terminated -A 6
Non-terminated Pods:          (3 in total)
  Namespace                   Name                         CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                         ------------  ----------  ---------------  -------------  ---
  kube-system                 aws-node-5jwzn               50m (2%)      0 (0%)      0 (0%)           0 (0%)         53m
  kube-system                 kube-proxy-69754             100m (5%)     0 (0%)      0 (0%)           0 (0%)         84m
```

Let's capture the pod name

```bash test=false
$ AWS_NODE_POD=$(kubectl get pods -n kube-system -l k8s-app=aws-node -o wide | grep $NODE_NAME| awk 'NR==1{print $1}')
```

Having identified the pod name, our next step is to examine the pod's details. Let's use the describe command to focus on the readiness status of each container within the pod.

```bash test=false
$ kubectl describe pods -n kube-system $AWS_NODE_POD

Containers:
  aws-node:
    Container ID:   containerd://24af57294e0285468b03bb7e5a27a3daa7d00834c20f915c67441197ac4fc869
    Image:          602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon-k8s-cni:v1.16.0-eksbuild.1
    Image ID:       602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon-k8s-cni@sha256:61e1a92ff2e63e3130db430c773736450fe941ed8701b77dd20ac6e8546f8255
    Port:           61678/TCP
    Host Port:      61678/TCP
    State:          Running
      Started:      Wed, 30 Oct 2024 20:52:21 +0000
    Last State:     Terminated
      Reason:       Error
      Exit Code:    2
      Started:      Wed, 30 Oct 2024 20:45:41 +0000
      Finished:     Wed, 30 Oct 2024 20:47:11 +0000
    Ready:          False
    Restart Count:  18
    Requests:
      cpu:      25m
    Liveness:   exec [/app/grpc-health-probe -addr=:50051 -connect-timeout=5s -rpc-timeout=5s] delay=60s timeout=10s period=10s #success=1 #failure=3
    Readiness:  exec [/app/grpc-health-probe -addr=:50051 -connect-timeout=5s -rpc-timeout=5s] delay=1s timeout=10s period=10s #success=1 #failure=3

    <REDACTED>

  aws-eks-nodeagent:
    Container ID:  containerd://a51df446be528d4dad3649b57ad2a53ae4dc163d230dabe275e20bced4c8b5d0
    Image:         602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-network-policy-agent:v1.0.7-eksbuild.1
    Image ID:      602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-network-policy-agent@sha256:0e7fd75230dee735c1636ad86d69bf38b1bc48e1b78459147957827d978e5635
    Port:          <none>
    Host Port:     <none>
    Args:
      --enable-ipv6=false
      --enable-network-policy=true
      --enable-cloudwatch-logs=false
      --enable-policy-event-logs=true
      --metrics-bind-addr=:8162
      --health-probe-bind-addr=:8163
      --conntrack-cache-cleanup-period=300
    State:          Running
      Started:      Wed, 30 Oct 2024 19:52:36 +0000
    Ready:          True
    Restart Count:  0
```

The output reveals that the aws-node container within the aws-node pod is not transitioning to a ready state (Ready=False). This is likely due to a failed Readiness probe, which is configured for the container. To resolve this issue, investigate the aws-node container to identify and address the factors preventing the Readiness probe from passing.

### Step 6

Now, let's examine the event section of the describe pod output. Identify this crucial information and be prepared to analyze it.

```bash test=false
$ kubectl describe pods -n kube-system aws-node
Events:
  Type     Reason                 Age                    From      Message
  ----     ------                 ----                   ----      -------
  Warning  MissingIAMPermissions  33m (x2 over 33m)      aws-node  Unauthorized operation: failed to call ec2:DescribeNetworkInterfaces due to missing permissions. Please refer https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/iam-policy.md to attach relevant policy to IAM role
  Warning  MissingIAMPermissions  31m (x2 over 31m)      aws-node  Unauthorized operation: failed to call ec2:DescribeNetworkInterfaces due to missing permissions. Please refer https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/iam-policy.md to attach relevant policy to IAM role
  Warning  MissingIAMPermissions  53m (x2 over 53m)      aws-node  Unauthorized operation: failed to call ec2:DescribeNetworkInterfaces due to missing permissions. Please refer https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/iam-policy.md to attach relevant policy to IAM role
```

This error suggests that the aws-node/L-IPAMD component lacks the necessary permissions to access the EC2 API, specifically the ec2:DescribeNetworkInterfaces action.

### Step 7

Let's verify the VPC CNI IAM role whether it has the required **AmazonEKS_CNI_Policy** managed policy. This policy should be associated with IAM role assigned during the VPC CNI addon configuration update in Step 5. Let's check the role's policies to confirm this.

:::info
For your convenience, we have set the environment variable **VPC_CNI_IAM_ROLE_NAME** to contain the name of the IAM role associated with the VPC CNI managed add-on.
:::

```bash
$ aws iam list-attached-role-policies --role-name $VPC_CNI_IAM_ROLE_NAME
{
    "AttachedPolicies": []
}
```

We now know that the VPC CNI role is missing **AmazonEKS_CNI_Policy**.

### Step 8

Having identified the missing policy, let's resolve this issue by attaching the necessary IAM managed policy. Execute the following command to implement the fix:

```bash timeout=180 hook=fix-5 hookTimeout=600
$ aws iam attach-role-policy --role-name $VPC_CNI_IAM_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
```

Let's confirm the attachment of the specified IAM managed policy to the VPC CNI add-ons role

```bash
$ aws iam list-attached-role-policies --role-name $VPC_CNI_IAM_ROLE_NAME
{
    "AttachedPolicies": [
        {
            "PolicyName": "AmazonEKS_CNI_Policy",
            "PolicyArn": "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        }
    ]
}
```

Allow a few minutes for aws-node to process the changes. Monitor the status until aws-node displays READY (2/2). Once confirmed, proceed to the next step

```bash
$ kubectl get pods -n kube-system -l k8s-app=aws-node -o wide
NAME             READY   STATUS    RESTARTS         AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
aws-node-5jwzn   2/2     Running   20 (6m38s ago)   69m   100.64.3.8      ip-100-64-3-8.us-west-2.compute.internal      <none>           <none>
aws-node-l8gzs   2/2     Running   0                70s   10.42.102.141   ip-10-42-102-141.us-west-2.compute.internal   <none>           <none>
aws-node-nqwjc   2/2     Running   0                66s   10.42.165.112   ip-10-42-165-112.us-west-2.compute.internal   <none>           <none>
aws-node-zwxhf   2/2     Running   20 (6m18s ago)   69m   10.42.145.11    ip-10-42-145-11.us-west-2.compute.internal    <none>           <none>
```

Ensure all nodes are in a 'Ready' state before proceeding.

```bash
$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-102-141.us-west-2.compute.internal   Ready    <none>   179m   v1.30.0-eks-036c24b
ip-10-42-145-11.us-west-2.compute.internal    Ready    <none>   179m   v1.30.0-eks-036c24b
ip-10-42-165-112.us-west-2.compute.internal   Ready    <none>   179m   v1.30.0-eks-036c24b
ip-100-64-3-8.us-west-2.compute.internal      Ready    <none>   101m   v1.30.4-eks-a737599
```

Verify that all app containers are scheduled to a node and display a 'ContainerCreating' status. This indicates proper initial deployment

```bash
$ kubectl get pods -n cni-tshoot -o wide
NAME                         READY   STATUS              RESTARTS   AGE   IP       NODE                                       NOMINATED NODE   READINESS GATES
nginx-app-5cf4cbfd97-2v8tp   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-5nw9n   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-9vf6k   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-bmtb2   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-d9wcn   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-lplnw   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-n2whf   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-pxf57   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-sb4fm   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-spv2b   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-v2xp2   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-vllxz   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-wbvtv   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-wm7xd   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
nginx-app-5cf4cbfd97-wn9lc   0/1     ContainerCreating   0          85m   <none>   ip-100-64-3-8.us-west-2.compute.internal   <none>           <none>
```
