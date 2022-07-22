---
title: "Node Termination Handler"
chapter: true
weight: 20
---

# Node Termination Handler

Node Termination Handler (NTH) ensures that the Kubernetes control plane responds appropriately to events that can cause your EC2 instance to become unavailable, such as EC2 maintenance events, EC2 Spot interruptions, ASG Scale-In, ASG AZ Rebalance, and EC2 Instance Termination via the API or Console. If not handled, your application code may not stop gracefully, take longer to recover full availability, or accidentally schedule work to nodes that are going down. For more information see [README.md](https://github.com/aws/aws-node-termination-handler#readme).

NTH can operate in two different modes: Instance Metadata Service (IMDS) or the Queue Processor.

The aws-node-termination-handler **[Instance Metadata Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) Monitor** will run a small pod on each host to perform monitoring of IMDS paths like `/spot` or `/events` and react accordingly to drain and/or cordon the corresponding node.

The aws-node-termination-handler **Queue Processor** will monitor an SQS queue of events from Amazon EventBridge for ASG lifecycle events, EC2 status change events, Spot Interruption Termination Notice events, and Spot Rebalance Recommendation events. When NTH detects an instance is going down, we use the Kubernetes API to cordon the node to ensure no new work is scheduled there, then drain it, removing any existing work. The termination handler **Queue Processor** requires AWS IAM permissions to monitor and manage the SQS queue and to query the EC2 API.

In this workshop, EKS Blueprints add-on for [node termination handler](https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/modules/kubernetes-addons/aws-node-termination-handler) has been enabled, which provisioned NTH in Queue Processor mode. This means that NTH will monitor an SQS queue of events from Amazon EventBridge for ASG lifecycle events, EC2 status change events, Spot Interruption Termination Notice events, and Spot Rebalance Recommendation events. 

For this chapter, we will

* Deploy a sample application
* Simulate [AutoScaling Group Scale-In](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroupLifecycle.html#as-lifecycle-scale-in) by reducing the number of EC2 instances in ASG by 1.
* See Node Termination Handler in action by ensuring application resiliency.