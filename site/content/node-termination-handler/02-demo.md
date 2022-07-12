---
title: "Simulation"
weight: 40
---

In this chapter, we will simulate scale down action by reducing the number of EC2 instances in the autoscaling group by 1. If node termination handler works as expected, then we should not see any impacts to the deployed sample application and the pods should get moved over to a healthy node gracefully.


1. Run the application in loop. Following will send a request to application every second.

```bash
export NTH_LB=$(kubectl get service nlb-sample-service  \-\-output=jsonpath='{.status.loadBalancer.ingress[0].hostname}' -n eks-sample-nth)
while sleep 1; do curl -s -o /dev/null -w "%{http_code}" -I http://$NTH_LB; done
```

2. Open a new command terminal and set the number of EC2 instances in autoscaling groups to 3. The command will not take any actions, if the desired instance count is already set to 3.

```bash
#ASSUMPTION - EKS_CLUSTER_NAME is already set by workshop framework
export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='$EKS_CLUSTER_NAME']].AutoScalingGroupName" --output text)

aws autoscaling set-desired-capacity --auto-scaling-group-name $ASG_NAME --desired-capacity 3
```

3. Now, reduce the `desired capacity` in the autoscaling group by 1

```bash
aws autoscaling set-desired-capacity --auto-scaling-group-name $ASG_NAME --desired-capacity 2
```

**Expected behavior** Within few seconds, autoscaling will terminate one EC2 instance. However, you should continue seeing response codes `200` in the first terminal window as the node termination handler will corden off and then drain all the pods running on the node which is getting terminated. You may additionally view the logs of the node terminational handler logs by running `kubectl logs deployment.apps/aws-node-termination-handler -n kube-system`

**Sample Logs**
{{< output >}}
2022/07/12 23:39:07 INF Adding new event to the event store 
2022/07/12 23:39:08 INF Requesting instance drain event-id=ec2-state-change-event-38663731306238612d643035382d306635632d646538662d373433643332363337303564 instance-id=i-01f40729ac05c4112 kind=SQS_TERMINATE node-name=ip-10-42-10-202.ec2.internal provider-id=aws:///us-east-1a/i-01f40729ac05c4112

2022/07/12 23:39:08 INF Pods on node node_name=ip-10-42-10-202.ec2.internal pod_names=["aws-node-jnmrw","kube-proxy-s86lm"]

2022/07/12 23:39:08 INF Draining the node

2022/07/12 23:39:08 ??? WARNING: ignoring DaemonSet-managed Pods: kube-system/aws-node-jnmrw, kube-system/kube-proxy-s86lm

2022/07/12 23:39:08 INF Node successfully cordoned and drained node_name=ip-10-42-10-202.ec2.internal reason="EC2 State Change event received. Instance i-01f40729ac05c4112 went into shutting-down at 2022-07-12 23:39:07 +0000 UTC \n"
{{< /output >}}