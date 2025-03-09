---
title: "Fixing Policy Issue"
sidebar_position: 42
---

In this hands-on troubleshooting exercise, you will continue troubleshooting from the previous scenario. The VPC CNI configurations are now corrected, however nginx-app pods are still stuck in the Pending status. 

## Let's start the troubleshooting

### Step 1: Verify Pod Status

Let's first verify the status of the pods:

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

### Step 2: Check Node Status

Now, let's check the status of the nodes:

```bash
$ kubectl get nodes -L app
NAME                                          STATUS     ROLES    AGE    VERSION               APP
ip-10-42-102-141.us-west-2.compute.internal   Ready      <none>   160m   v1.30.0-eks-036c24b
ip-10-42-145-11.us-west-2.compute.internal    Ready      <none>   160m   v1.30.0-eks-036c24b
ip-10-42-165-112.us-west-2.compute.internal   Ready      <none>   160m   v1.30.0-eks-036c24b
ip-100-64-3-8.us-west-2.compute.internal      NotReady   <none>   82m    v1.30.4-eks-a737599   cni_troubleshooting
```

We can see that the new node (example above: ip-100-64-3-8.us-west-2.compute.internal) is in a NotReady state.

### Step 3: Investigate Node Conditions

Let's examine the node's conditions to understand why it's in a NotReady state:

```bash test=false
$ kubectl describe node $NODE_NAME | sed -n '/^Conditions:/,/^Addresses:/ p' | head -n -1
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Wed, 30 Oct 2024 20:43:45 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Wed, 30 Oct 2024 20:43:45 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Wed, 30 Oct 2024 20:43:45 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Wed, 30 Oct 2024 20:43:45 +0000   Wed, 30 Oct 2024 19:21:08 +0000   KubeletNotReady              container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized
```

The output indicates that the network plugin is not initialized.
:::info
To ensure EKS worker nodes become Ready when using the default AWS VPC CNI, all containers in the aws-node pod must be ready
:::

### Step 4: Check aws-node Pod Status

Let's identify and examine the aws-node pod on the problematic node:

```bash test=false
$ kubectl describe node $NODE_NAME | sed -n '/^Non-terminated Pods:/,/^Allocated resources:/ p' | head -n -1
Non-terminated Pods:          (3 in total)
  Namespace                   Name                         CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                         ------------  ----------  ---------------  -------------  ---
  kube-system                 aws-node-5jwzn               50m (2%)      0 (0%)      0 (0%)           0 (0%)         53m
  kube-system                 kube-proxy-69754             100m (5%)     0 (0%)      0 (0%)           0 (0%)         84m
```

Let's capture the pod name:

```bash 
$ AWS_NODE_POD=$(kubectl get pods -n kube-system -l k8s-app=aws-node -o wide | grep $NODE_NAME| awk 'NR==1{print $1}')
```

Now, let's describe the aws-node pod:

```bash 
$ kubectl describe pods -n kube-system $AWS_NODE_POD | sed -n '/Containers:/,/Environment:/p' | sed '$d' 
...
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
...
```
The aws-node container within the aws-node pod is not transitioning to a ready state (Ready=False).

### Step 5: Examine Pod Events

Let's check the events section of the aws-node pod:

```bash test=false
$ kubectl describe pods -n kube-system $AWS_NODE_POD | sed -n '/Events:/,$p' 
Events:
  Type     Reason                 Age                    From      Message
  ----     ------                 ----                   ----      -------
  Warning  MissingIAMPermissions  33m (x2 over 33m)      aws-node  Unauthorized operation: failed to call ec2:DescribeNetworkInterfaces due to missing permissions. Please refer https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/iam-policy.md to attach relevant policy to IAM role
  Warning  MissingIAMPermissions  31m (x2 over 31m)      aws-node  Unauthorized operation: failed to call ec2:DescribeNetworkInterfaces due to missing permissions. Please refer https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/iam-policy.md to attach relevant policy to IAM role
  Warning  MissingIAMPermissions  53m (x2 over 53m)      aws-node  Unauthorized operation: failed to call ec2:DescribeNetworkInterfaces due to missing permissions. Please refer https://github.com/aws/amazon-vpc-cni-k8s/blob/master/docs/iam-policy.md to attach relevant policy to IAM role
```

The events indicate that the aws-node lacks the necessary permissions to access the EC2 API.

### Step 6: Verify VPC CNI IAM Role

Let's check if the VPC CNI IAM role has the required AmazonEKS_CNI_Policy:

:::info
For your convenience, the VPC CNI IAM role is configured as environment variable ***VPC_CNI_IAM_ROLE_NAME***.
:::

```bash
$ aws iam list-attached-role-policies --role-name $VPC_CNI_IAM_ROLE_NAME
{
    "AttachedPolicies": []
}
```

We can see that the VPC CNI role is missing the **AmazonEKS_CNI_Policy**.

### Step 7: Attach the Required IAM Policy

Let's attach the necessary IAM managed policy:

```bash timeout=180 hook=fix-5 hookTimeout=600
$ aws iam attach-role-policy --role-name $VPC_CNI_IAM_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
```

Now, let's confirm that the policy has been attached:

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

### Step 8: Verify aws-node Pod Status

Allow a few minutes for aws-node to process the changes, then check its status and container readiness (READY should be 2/2):

```bash
$ kubectl get pods -n kube-system -l k8s-app=aws-node -o wide
NAME             READY   STATUS    RESTARTS         AGE   IP              NODE                                          NOMINATED NODE   READINESS GATES
aws-node-5jwzn   2/2     Running   20 (6m38s ago)   69m   100.64.3.8      ip-100-64-3-8.us-west-2.compute.internal      <none>           <none>
aws-node-l8gzs   2/2     Running   0                70s   10.42.102.141   ip-10-42-102-141.us-west-2.compute.internal   <none>           <none>
aws-node-nqwjc   2/2     Running   0                66s   10.42.165.112   ip-10-42-165-112.us-west-2.compute.internal   <none>           <none>
aws-node-zwxhf   2/2     Running   20 (6m18s ago)   69m   10.42.145.11    ip-10-42-145-11.us-west-2.compute.internal    <none>           <none>
```
:::note
You can also delete the aws-node pod to start up a new daemonset pod to speed up the process.
```bash test=false
$ kubectl delete po $AWS_NODE_POD -n kube-system
```
:::
### Step 9: Verify Node Status

Ensure all nodes are in a 'Ready' state:

```bash
$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-102-141.us-west-2.compute.internal   Ready    <none>   179m   v1.30.0-eks-036c24b
ip-10-42-145-11.us-west-2.compute.internal    Ready    <none>   179m   v1.30.0-eks-036c24b
ip-10-42-165-112.us-west-2.compute.internal   Ready    <none>   179m   v1.30.0-eks-036c24b
ip-100-64-3-8.us-west-2.compute.internal      Ready    <none>   101m   v1.30.4-eks-a737599
```

### Step 10: Verify Application Pod Status

Check that all application containers are no longer pending and scheduled. 

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

:::info
Pods are expected to be in ContainerCreating status for the next scenario. 
:::

### Conclusion

In this troubleshooting exercise, we identified and resolved an IAM permission issue that was preventing the AWS VPC CNI plugin from functioning correctly. Here's a summary of what we learned:

#### Problem Identification:
      - The nginx-app pods were stuck in Pending state
      - The worker node was in NotReady state
      - The aws-node pod was running, but not Ready
      - Events showed missing IAM permissions for EC2 API calls

 #### Root Cause:
      - The VPC CNI IAM role was missing the required AmazonEKS_CNI_Policy
      - This prevented the aws-node pod from managing ENIs and IP addresses

  #### Resolution Steps:
      - We verified the missing IAM policy
      - Attached the AmazonEKS_CNI_Policy to the VPC CNI IAM role
      - Confirmed the aws-node pod reached Ready state
      - Verified the worker node transitioned to Ready state

   #### Key Takeaways:
       - Always ensure proper IAM permissions are configured for EKS add-ons
       - The aws-node DaemonSet requires specific IAM permissions to manage networking
       - Pod scheduling issues can often be traced back to node readiness problems

### Additional Resources

  - [AWS VPC CNI IAM Role Documentation](https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html)
  - [EKS Pod Networking Troubleshooting Guide](https://aws.github.io/aws-eks-best-practices/networking/vpc-cni/)
  - [AWS VPC CNI GitHub Repository](https://github.com/aws/amazon-vpc-cni-k8s)
