---
title: "Expanding Worker Node Subnet"
sidebar_position: 43
---

### Step 9

Congratulations, The nginx-app pods have been scheduled on the new node. However, they are stuck in the ContainerCreating state. To troubleshoot this issue, describe one of the affected pods and examine the Events section of the output. This will help identify the root cause of the problem.

```bash test=false
$ kubectl describe pod -n cni-tshoot
Events:
  Type     Reason                  Age                  From               Message
  ----     ------                  ----                 ----               -------
  Warning  FailedScheduling        23m (x15 over 93m)   default-scheduler  0/4 nodes are available: 1 node(s) had untolerated taint {node.kubernetes.io/not-ready: }, 3 node(s) didn't match Pod's node affinity/selector. preemption: 0/4 nodes are available: 4 Preemption is not helpful for scheduling.
  Normal   Scheduled               23m                  default-scheduler  Successfully assigned cni-tshoot/nginx-app-5cf4cbfd97-2v8tp to ip-100-64-3-8.us-west-2.compute.internal
  Warning  FailedCreatePodSandBox  23m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "14bffa7734d01abd808dead23744386135518961ab240ba48b88a9e269398126": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  23m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "1c18b4373dd31dcc13500dd1f8465bf34ce1659560b9ad430ff75d543b9d6775": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  22m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "de3888bd06bb284aafe0531c42c672a0019351f3346b64e30813007ac04b8c43": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  22m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "44223b1930b6a487866048dd918c752e6b69a5da00bc48fa24552a4446bcc1fb": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  22m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "fdbafbf1c5c543ba8667a49156116d4892d9cfaabc413fb7e4bf80e242eb137d": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  22m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "a791bb0db767a4df6a51c5b8ce3a3139683bb65785d45bb05f4f42ad6db0ca83": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  21m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "badb3b775bcde51577e9a1bceb0c38f87d7df34a6fa7282799e9febf0d715e71": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  21m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "c8472dc0407b051e786bc9bd2a3b277a514b4f4897e3ac186c349b3061b219da": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  21m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "ba6330c1dc7d5bcf715a635569c54e1eb67f40ea26aa00db56d54e6ddb25ea7f": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
  Warning  FailedCreatePodSandBox  3m7s (x84 over 21m)  kubelet            (combined from similar events): Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "ee02fa03d490b4d0691df0f8db608a7c5c4c7983b498eee620a9494c31eb1628": plugin type="aws-cni" name="aws-cni" failed (add): add cmd: failed to assign an IP address to container
```

:::info VPC CNI Overview and Troubleshooting:

The VPC CNI (Container Network Interface) operates by placing the aws-cni binary in the /opt/cni/bin directory of each node. This binary plays a crucial role during pod creation:

- It's executed when a pod's network namespace is created.
- It requests an available IP address from the L-IPAMD (IP Address Management Daemon), also known as aws-node.
- This request is made via a gRPC call to a local socket on port 50051.

When troubleshooting network issues, focus on two main components:

- The aws-cni binary logs (/var/log/aws-routed-eni/plugin.log)
- The L-IPAMD (aws-node) logs (/var/log/aws-routed-eni/ipamd.log)

**Note**: These logs are typically only accessible from the node itself. To facilitate log collection, AWS provides a specialized tool called [the EKS Log Collector](https://github.com/awslabs/amazon-eks-ami/tree/main/log-collector-script/). You can find this script in the Amazon EKS AMI GitHub repository.
:::

The next step, we'll utilize the AWS Systems Manager (SSM) Agent to execute commands on our EKS nodes. The SSM Agent is pre-installed on EKS Optimized Amazon Machine Images (AMIs). To enable its functionality, we need to attach the **AmazonSSMManagedInstanceCore** IAM managed policy to the IAM role associated with the node. We've prepared a script to assist you in retrieving logs from the underlying EC2 instance.

```bash test=false
$ cat eks-workshop/modules/troubleshooting/cni/.workshop/ssm.sh

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

### Step 10

First, we'll select a representative pod name as our focus

```bash
$ export POD_NAME=$(kubectl get pods -n cni-tshoot -o custom-columns=:metadata.name --no-headers | awk 'NR==1{print $1}')
```

Next, we'll identify the specific node where our pod is currently running by retrieving its instance ID

```bash
$ export NODE_NAME=$(kubectl get pod $POD_NAME -n cni-tshoot -o custom-columns=:spec.nodeName --no-headers)
$ export NODE_ID=$(kubectl get node $NODE_NAME -o=jsonpath='{.spec.providerID}' | cut -d "/" -f 5)
```

Now that we have completed the setup, let's confirm that the CNI plugin received the request to provision a network namespace for the pod named $POD_NAME. This verification step is crucial to ensure proper communication between the container runtime and VPC CNI plugin.

```bash test=false
$ bash eks-workshop/modules/troubleshooting/cni/.workshop/ssm.sh $NODE_ID plugin 200 $POD_NAME
{"level":"info","ts":"2024-10-30T21:31:30.508Z","caller":"routed-eni-cni-plugin/cni.go:125","msg":"Received CNI add request: ContainerID(493b063c06e901827b21737af8d543a77f724b2d8ce97d650a6d1703b724a549) Netns(/var/run/netns/cni-5b637183-286d-95ec-1c4a-de61ed54de26) IfName(eth0) Args(K8S_POD_INFRA_CONTAINER_ID=493b063c06e901827b21737af8d543a77f724b2d8ce97d650a6d1703b724a549;K8S_POD_UID=53b79f5f-dc74-454d-bdde-5a9282ac6ace;IgnoreUnknown=1;K8S_POD_NAMESPACE=cni-tshoot;K8S_POD_NAME=nginx-app-5cf4cbfd97-2v8tp) Path(/opt/cni/bin) argsStdinData({\"cniVersion\":\"1.0.0\",\"mtu\":\"9001\",\"name\":\"aws-cni\",\"pluginLogFile\":\"/var/log/aws-routed-eni/plugin.log\",\"pluginLogLevel\":\"DEBUG\",\"podSGEnforcingMode\":\"standard\",\"type\":\"aws-cni\",\"vethPrefix\":\"eni\"})"}
{"level":"info","ts":"2024-10-30T21:31:30.545Z","caller":"routed-eni-cni-plugin/cni.go:282","msg":"Received CNI del request: ContainerID(493b063c06e901827b21737af8d543a77f724b2d8ce97d650a6d1703b724a549) Netns(/var/run/netns/cni-5b637183-286d-95ec-1c4a-de61ed54de26) IfName(eth0) Args(IgnoreUnknown=1;K8S_POD_NAMESPACE=cni-tshoot;K8S_POD_NAME=nginx-app-5cf4cbfd97-2v8tp;K8S_POD_INFRA_CONTAINER_ID=493b063c06e901827b21737af8d543a77f724b2d8ce97d650a6d1703b724a549;K8S_POD_UID=53b79f5f-dc74-454d-bdde-5a9282ac6ace) Path(/opt/cni/bin) argsStdinData({\"cniVersion\":\"1.0.0\",\"mtu\":\"9001\",\"name\":\"aws-cni\",\"pluginLogFile\":\"/var/log/aws-routed-eni/plugin.log\",\"pluginLogLevel\":\"DEBUG\",\"podSGEnforcingMode\":\"standard\",\"type\":\"aws-cni\",\"vethPrefix\":\"eni\"})"}
```

Excellent! We've confirmed that the CNI plugin successfully received the request to set up the network namespace for pod $POD_NAME. Our next step is to check if the L-IPAMD received an IP address request from the CNI plugin for this specific pod.

```bash test=false
$ bash eks-workshop/modules/troubleshooting/cni/.workshop/ssm.sh $NODE_ID ipamd 200 $POD_NAME
{"level":"debug","ts":"2024-10-30T21:32:23.519Z","caller":"rpc/rpc.pb.go:713","msg":"AddNetworkRequest: K8S_POD_NAME:\"nginx-app-5cf4cbfd97-2v8tp\"  K8S_POD_NAMESPACE:\"cni-tshoot\"  K8S_POD_INFRA_CONTAINER_ID:\"1921d4fa98f25f481b0d5935eebd0e8e4b8c2b937b2d98277828ada327069393\"  ContainerID:\"1921d4fa98f25f481b0d5935eebd0e8e4b8c2b937b2d98277828ada327069393\"  IfName:\"eth0\"  NetworkName:\"aws-cni\"  Netns:\"/var/run/netns/cni-65045971-ebe5-d672-a6b5-f7690545d61e\""}
{"level":"debug","ts":"2024-10-30T21:32:23.556Z","caller":"rpc/rpc.pb.go:731","msg":"DelNetworkRequest: K8S_POD_NAME:\"nginx-app-5cf4cbfd97-2v8tp\"  K8S_POD_NAMESPACE:\"cni-tshoot\"  K8S_POD_INFRA_CONTAINER_ID:\"1921d4fa98f25f481b0d5935eebd0e8e4b8c2b937b2d98277828ada327069393\"  Reason:\"PodDeleted\"  ContainerID:\"1921d4fa98f25f481b0d5935eebd0e8e4b8c2b937b2d98277828ada327069393\"  IfName:\"eth0\"  NetworkName:\"aws-cni\""}
```

Great! We've confirmed that the L-IPAMD successfully received an IP address request for the pod named $POD_NAME from the CNI plugin. Our next step is to examine the IP address pool managed by the IPAMD at the time this request was processed.

```bash test=false
$ bash eks-workshop/modules/troubleshooting/cni/.workshop/ssm.sh $NODE_ID ipamd 200 datastore/data
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

Upon examination, we've discovered that the IP Address Management (IPAMD) warm pool is currently empty. This indicates that we should shift our focus to investigating the configuration of the Virtual Private Cloud (VPC) subnets.

### Step 11

As we turn our attention to VPC subnet configuration, our first step is to locate the subnet where the worker node instances are deployed. Once identified, we'll examine the number of available IP addresses within that subnet.

```bash
$ export NODE_SUBNET=$(aws ec2 describe-instances --instance-ids $NODE_ID --query 'Reservations[0].Instances[0].SubnetId' --output text)
$ aws ec2 describe-subnets --subnet-ids $NODE_SUBNET --output text --query 'Subnets[0].AvailableIpAddressCount'
10
```

We've identified that this particular node's subnet is running low on available IP addresses. To get a comprehensive view of the situation, it's important to assess the IP address availability across all subnets associated with this nodegroup. Let's proceed to examine the remaining subnets within this nodegroup to determine their current IP address capacity.

```bash
$ export NODE_GROUP_SUBNETS=$(aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name cni_troubleshooting_nodes --query 'nodegroup.subnets' --output text)
$ aws ec2 describe-subnets --subnet-ids $NODE_GROUP_SUBNETS --output text --query 'Subnets[*].AvailableIpAddressCount'
11      11      10
```

Having identified that our existing node subnets are running low on available IP addresses, we need to take action. The solution is to create a new nodegroup that utilizes subnets with a larger pool of available IPs. It's important to note that we cannot modify an existing nodegroup to use different subnets, which is why creating a new nodegroup is necessary.

### Step 12

When expanding your EKS cluster, it's possible to create new subnets for additional node groups, even if these subnets weren't part of the original cluster configuration.
:::info
In our case, we've established new subnets on a secondary VPC CIDR to accommodate our new node groups, they are defined in these environment variables

1. **ADDITIONAL_SUBNET_1**
2. **ADDITIONAL_SUBNET_2**
3. **ADDITIONAL_SUBNET_3**

:::

Before we move forward with creating a new managed nodegroup, it's essential to confirm that there are sufficient IP addresses available in these newly created subnets.

```bash
$ aws ec2 describe-subnets --subnet-ids $ADDITIONAL_SUBNET_1 $ADDITIONAL_SUBNET_2 $ADDITIONAL_SUBNET_3 --output text --query 'Subnets[*].AvailableIpAddressCount'
251     251     251
```

Now that we've confirmed the availability of sufficient IP addresses, we can proceed to create a new managed node group.

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

During the creation of the new node group, we'll initiate a scale-in process for the existing node group. This action will encourage the automatic rescheduling of pods onto the newly created nodes, ensuring a smooth transition to the updated infrastructure.

```bash timeout=180 hook=fix-9 hookTimeout=600
$ aws eks update-nodegroup-config --cluster-name $EKS_CLUSTER_NAME --nodegroup-name cni_troubleshooting_nodes --scaling-config minSize=0,maxSize=1,desiredSize=0
```

After the new node group becomes fully operational and the old node group has scaled down completely, you should observe that all your nginx-app pods are in a **Running** state.

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

### Congratulations! you deserve a pat on the back
