---
title: "Expanding Worker Node Subnet"
sidebar_position: 43
---

In this hands-on troubleshooting exercise, you will continue troubleshooting from the previous scenarios. The VPC CNI configurations and permissions are now corrected, however nginx-app pods are still in the ContainerCreating status. 

## Let's start the troubleshooting

### Step 1: Verify Pod Status

Let's first verify the status of the nginx-app pods:

```bash
$ kubectl get pods -n cni-tshoot
NAME                         READY   STATUS              RESTARTS   AGE
nginx-app-5cf4cbfd97-2v8tp   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-4m9xk   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-5strx   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-6rz56   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-866kt   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-8h2dg   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-9r98g   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-f5gxn   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-kqrf2   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-pp6vd   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-pth6m   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-q7rfd   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-rl6fp   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-rptlq   0/1     ContainerCreating   0          3m
nginx-app-5cf4cbfd97-t9cgr   0/1     ContainerCreating   0          3m
```


### Step 2: Examine Pod Events

Let's select one representative cni-tshoot pod and describe it to examine the Events section:


```bash
$ export POD_NAME=$(kubectl get pods -n cni-tshoot -o custom-columns=:metadata.name --no-headers | awk 'NR==1{print $1}')
```

```bash
$ kubectl describe pod $POD_NAME -n cni-tshoot | sed -n '/^Events:/,$ p'

Events:
  Type     Reason                  Age                  From               Message
  ----     ------                  ----                 ----               -------
  Warning  FailedScheduling        23m (x15 over 93m)   default-scheduler  0/4 nodes are available: 1 node(s) had untolerated taint {node.kubernetes.io/not-ready: }, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
  Normal   Scheduled               23m                  default-scheduler  Successfully assigned cni-tshoot/nginx-app-5cf4cbfd97-2v8tp to ip-100-64-3-8.us-west-2.compute.internal
  Warning  FailedCreatePodSandBox  23m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "14bffa7734d01abd808dead23744386135518961ab240ba48b88a9e269398126": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  23m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "1c18b4373dd31dcc13500dd1f8465bf34ce1659560b9ad430ff75d543b9d6775": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  ...
  Warning  FailedCreatePodSandBox  3m7s (x84 over 21m)  kubelet            (combined from similar events): Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "ee02fa03d490b4d0691df0f8db608a7c5c4c7983b498eee620a9494c31eb1628": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
```
:::info VPC CNI Overview and Troubleshooting:

The VPC CNI (Container Network Interface) operates by placing the aws-cni binary in the /opt/cni/bin directory of each node. 

- It's executed when a pod's network namespace is created.
- It requests an available IP address from the L-IPAMD (IP Address Management Daemon), also known as aws-node.
- This request is made via a gRPC call to a local socket on port 50051.

Check the following logs when troubleshooting:
- The aws-cni binary logs (/var/log/aws-routed-eni/plugin.log)
- The L-IPAMD (aws-node) logs (/var/log/aws-routed-eni/ipamd.log)

**Note**: These logs are accessible from the node itself. To facilitate log collection, AWS provides a specialized tool called [the EKS Log Collector](https://github.com/awslabs/amazon-eks-ami/tree/main/log-collector-script/).
:::

### Step 3: Investigate VPC CNI Logs

We'll use AWS Systems Manager (SSM) to execute commands on our EKS nodes. First, let's select the node name and ID to prepare the SSM command:


```bash
$ export NODE_NAME=$(kubectl get pod $POD_NAME -n cni-tshoot -o custom-columns=:spec.nodeName --no-headers)
```
```bash
$ export NODE_ID=$(kubectl get node $NODE_NAME -o=jsonpath='{.spec.providerID}' | cut -d "/" -f 5)
```

:::info
To execute SSM commands to the node, **AmazonSSMManagedInstanceCore** IAM managed policy needs to be associated with the node's IAM role. We've prepared a script to assist you in retrieving logs from the underlying EC2 instance.

```bash test=false
$ cat ~/environment/eks-workshop/modules/troubleshooting/cni/.workshop/ssm.sh

#!/bin/bash
COMMAND_ID=$(aws ssm send-command \
    --instance-ids $1 \
    --document-name "AWS-RunShellScript" \
    --comment "Demo run shell script on Linux Instances" \
    --parameters '{"commands":["sudo -Hiu root bash << END","tail -n '$3' /var/log/aws-routed-eni/'$2'.log | grep '$4'", "END"]}' \
    --output text \
    --query "Command.CommandId")

STATUS=InProgress
while [ "$STATUS" == "InProgress" ]; do
    STATUS=$(aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id $1 \
        --output text \
        --query "Status")
done

aws ssm list-command-invocations \
    --command-id "$COMMAND_ID" \
    --details \
    --output text \
    --query "CommandInvocations[].CommandPlugins[].Output"
```
:::
Now, let's check the CNI plugin logs.

```bash
$ bash ~/environment/eks-workshop/modules/troubleshooting/cni/.workshop/ssm.sh $NODE_ID plugin 200 $POD_NAME
{"level":"info","ts":"2024-10-30T21:31:30.508Z","caller":"routed-eni-cni-plugin/cni.go:125","msg":"Received CNI add request: ContainerID(493b063c06e901827b21737af8d543a77f724b2d8ce97d650a6d1703b724a549) Netns(/var/run/netns/cni-5b637183-286d-95ec-1c4a-de61ed54de26) IfName(eth0) Args(K8S_POD_INFRA_CONTAINER_ID=493b063c06e901827b21737af8d543a77f724b2d8ce97d650a6d1703b724a549;K8S_POD_UID=53b79f5f-dc74-454d-bdde-5a9282ac6ace;IgnoreUnknown=1;K8S_POD_NAMESPACE=cni-tshoot;K8S_POD_NAME=nginx-app-5cf4cbfd97-2v8tp) Path(/opt/cni/bin) argsStdinData({\"cniVersion\":\"1.0.0\",\"mtu\":\"9001\",\"name\":\"aws-cni\",\"pluginLogFile\":\"/var/log/aws-routed-eni/plugin.log\",\"pluginLogLevel\":\"DEBUG\",\"podSGEnforcingMode\":\"standard\",\"type\":\"aws-cni\",\"vethPrefix\":\"eni\"})"}
{"level":"info","ts":"2024-10-30T21:31:30.545Z","caller":"routed-eni-cni-plugin/cni.go:282","msg":"Received CNI del request: ContainerID(493b063c06e901827b21737af8d543a77f724b2d8ce97d650a6d1703b724a549) Netns(/var/run/netns/cni-5b637183-286d-95ec-1c4a-de61ed54de26) IfName(eth0) Args(IgnoreUnknown=1;K8S_POD_NAMESPACE=cni-tshoot;K8S_POD_NAME=nginx-app-5cf4cbfd97-2v8tp;K8S_POD_INFRA_CONTAINER_ID=493b063c06e901827b21737af8d543a77f724b2d8ce97d650a6d1703b724a549;K8S_POD_UID=53b79f5f-dc74-454d-bdde-5a9282ac6ace) Path(/opt/cni/bin) argsStdinData({\"cniVersion\":\"1.0.0\",\"mtu\":\"9001\",\"name\":\"aws-cni\",\"pluginLogFile\":\"/var/log/aws-routed-eni/plugin.log\",\"pluginLogLevel\":\"DEBUG\",\"podSGEnforcingMode\":\"standard\",\"type\":\"aws-cni\",\"vethPrefix\":\"eni\"})"}
```
:::info
the CNI plugin successfully received the request to set up the network namespace for pod $POD_NAME.
:::

Next, let's check the L-IPAMD logs:

```bash
$ bash ~/environment/eks-workshop/modules/troubleshooting/cni/.workshop/ssm.sh $NODE_ID ipamd 200 $POD_NAME
{"level":"debug","ts":"2024-10-30T21:32:23.519Z","caller":"rpc/rpc.pb.go:713","msg":"AddNetworkRequest: K8S_POD_NAME:\"nginx-app-5cf4cbfd97-2v8tp\"  K8S_POD_NAMESPACE:\"cni-tshoot\"  K8S_POD_INFRA_CONTAINER_ID:\"1921d4fa98f25f481b0d5935eebd0e8e4b8c2b937b2d98277828ada327069393\"  ContainerID:\"1921d4fa98f25f481b0d5935eebd0e8e4b8c2b937b2d98277828ada327069393\"  IfName:\"eth0\"  NetworkName:\"aws-cni\"  Netns:\"/var/run/netns/cni-65045971-ebe5-d672-a6b5-f7690545d61e\""}
{"level":"debug","ts":"2024-10-30T21:32:23.556Z","caller":"rpc/rpc.pb.go:731","msg":"DelNetworkRequest: K8S_POD_NAME:\"nginx-app-5cf4cbfd97-2v8tp\"  K8S_POD_NAMESPACE:\"cni-tshoot\"  K8S_POD_INFRA_CONTAINER_ID:\"1921d4fa98f25f481b0d5935eebd0e8e4b8c2b937b2d98277828ada327069393\"  Reason:\"PodDeleted\"  ContainerID:\"1921d4fa98f25f481b0d5935eebd0e8e4b8c2b937b2d98277828ada327069393\"  IfName:\"eth0\"  NetworkName:\"aws-cni\""}
```
:::info
The L-IPAMD successfully received an IP address request for the pod named $POD_NAME from the CNI plugin.
:::

Now, let's examine the IP address pool managed by the IPAMD:

```bash timeout=10 wait=5
$ bash ~/environment/eks-workshop/modules/troubleshooting/cni/.workshop/ssm.sh $NODE_ID ipamd 200 datastore/data
{"level":"debug","ts":"2024-10-30T21:32:54.531Z","caller":"datastore/data_store.go:607","msg":"AssignPodIPv4Address: IP address pool stats: total 0, assigned 0"}
{"level":"debug","ts":"2024-10-30T21:32:54.531Z","caller":"datastore/data_store.go:607","msg":"AssignPodIPv4Address: ENI eni-0ee6517834f4b39ac does not have available addresses"}
{"level":"error","ts":"2024-10-30T21:32:54.531Z","caller":"datastore/data_store.go:607","msg":"DataStore has no available IP/Prefix addresses"}
{"level":"debug","ts":"2024-10-30T21:32:54.564Z","caller":"datastore/data_store.go:607","msg":"AssignPodIPv4Address: IP address pool stats: total 0, assigned 0"}
{"level":"debug","ts":"2024-10-30T21:32:54.564Z","caller":"datastore/data_store.go:607","msg":"AssignPodIPv4Address: ENI eni-0ee6517834f4b39ac does not have available addresses"}
{"level":"error","ts":"2024-10-30T21:32:54.564Z","caller":"datastore/data_store.go:607","msg":"DataStore has no available IP/Prefix addresses"}
{"level":"debug","ts":"2024-10-30T21:32:56.559Z","caller":"datastore/data_store.go:607","msg":"AssignPodIPv4Address: IP address pool stats: total 0, assigned 0"}
{"level":"debug","ts":"2024-10-30T21:32:56.559Z","caller":"datastore/data_store.go:607","msg":"AssignPodIPv4Address: ENI eni-0ee6517834f4b39ac does not have available addresses"}
{"level":"error","ts":"2024-10-30T21:32:56.559Z","caller":"datastore/data_store.go:607","msg":"DataStore has no available IP/Prefix addresses"}
{"level":"debug","ts":"2024-10-30T21:32:56.566Z","caller":"datastore/data_store.go:607","msg":"AssignPodIPv4Address: IP address pool stats: total 0, assigned 0"}
```

:::info
IP Address Management (IPAMD) warm pool is currently empty.
:::

### Step 4: Investigate VPC Subnet Configuration

#### 4.1. Examine the VPC subnet configuration for available IP addresses

```bash
$ export NODE_SUBNET=$(aws ec2 describe-instances --instance-ids $NODE_ID --query 'Reservations[0].Instances[0].SubnetId' --output text)
```

```bash
$ aws ec2 describe-subnets --subnet-ids $NODE_SUBNET --output text --query 'Subnets[0].AvailableIpAddressCount'

9
```

#### 4.2. Check all subnets associated with the nodegroup

```bash
$ export NODE_GROUP_SUBNETS=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name cni_troubleshooting_nodes --query 'nodegroup.subnets' --output text)
```
```bash
$ aws ec2 describe-subnets --subnet-ids $NODE_GROUP_SUBNETS --output text --query 'Subnets[*].AvailableIpAddressCount'
9       11      11
```

:::info
Existing node subnets are running low on available IP addresses
:::
### Step 5: Create New Subnets with Larger IP Pools

We've already established new subnets on a secondary VPC CIDR. Let's verify their IP address availability:

```bash
$ aws ec2 describe-subnets --subnet-ids $ADDITIONAL_SUBNET_1 $ADDITIONAL_SUBNET_2 $ADDITIONAL_SUBNET_3 --output text --query 'Subnets[*].AvailableIpAddressCount'
251     251     251
```

### Step 6: Create a New Managed Node Group

Now, let's create a new managed node group using these subnets:

```bash
$ aws eks create-nodegroup --region $AWS_REGION \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name new-cni-nodes \
  --instance-types m5.large --node-role $NODEGROUP_IAM_ROLE \
  --subnets $ADDITIONAL_SUBNET_1 $ADDITIONAL_SUBNET_2 $ADDITIONAL_SUBNET_3 \
  --labels app=cni_troubleshooting \
  --taints key=purpose,value=cni_troubleshooting,effect=NO_SCHEDULE\
  --scaling-config minSize=1,maxSize=3,desiredSize=1 
```
Run the script below to check and wait for the nodegroup to be active.

```bash test=false
$ echo "Waiting for nodegroup to become active. This may take several minutes..." && aws eks wait nodegroup-active --region $AWS_REGION --cluster-name $EKS_CLUSTER_NAME --nodegroup-name new-cni-nodes && echo "Nodegroup 'new-cni-nodes' is now active!"

```

### Step 7: Scale Down the Old Node Group

Let's initiate a scale-in process for the existing node group:

```bash
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME --nodegroup-name cni_troubleshooting_nodes --scaling-config minSize=0,maxSize=1,desiredSize=0
```

### Step 8: Verify Pod Status

After the new node group becomes fully operational and the old node group has scaled down, check the status of the nginx-app pods:

```bash
$ kubectl get pods -n cni-tshoot
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-5cf4cbfd97-28lv7   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-5strx   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-6rz56   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-866kt   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-8h2dg   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-9r98g   1/1     Running   0          6m21s
nginx-app-5cf4cbfd97-f5gxn   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-kqrf2   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-pp6vd   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-pth6m   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-q7rfd   1/1     Running   0          6m21s
nginx-app-5cf4cbfd97-rl6fp   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-rptlq   1/1     Running   0          6m22s
nginx-app-5cf4cbfd97-t9cgr   1/1     Running   0          6m21s
nginx-app-5cf4cbfd97-zb8dk   1/1     Running   0          6m22s
```

### Conclusion

In this troubleshooting exercise, we identified and resolved an IP address exhaustion issue that was preventing pods from being scheduled. Here's a summary of what we learned:

#### Problem Identification:

- The nginx-app pods were stuck in ContainerCreating state
- The VPC CNI plugin was failing to assign IP addresses to containers
- The IPAMD reported no available IP addresses in its pool

#### Root Cause:

- The existing node subnets had very few available IP addresses
- This prevented the VPC CNI from allocating IPs to new pods

#### Resolution Steps:

- We verified the lack of available IPs in the existing subnets
- Created new subnets with larger IP address pools
- Launched a new managed node group using these subnets
- Scaled down the old node group to encourage pod rescheduling

#### Key Takeaways:

- Always ensure sufficient IP address space in your VPC subnets
- Monitor subnet IP utilization and plan for expansion
- Consider using larger CIDR blocks for node subnets in production environments
- Understand how the VPC CNI plugin manages IP addresses for pods

### Additional Resources
- [CNI Customer Network](https://docs.aws.amazon.com/eks/latest/userguide/cni-custom-network.html)
- [Optimizing IP Utilization](https://docs.aws.amazon.com/eks/latest/best-practices/ip-opt.html)
- [Increasing available IP addresses for your Amazon EC2 nodes](https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html)
