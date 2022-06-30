---
title: "Configure Cluster Autoscaler (CA)"
date: 2018-08-07T08:30:11-07:00
weight: 30
---

## Configure the ASG

You configure the size of your Auto Scaling group by setting the minimum, maximum, and desired capacity. When we created the cluster we set these settings to 3.

```bash
aws autoscaling \
    describe-auto-scaling-groups \
    --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eksworkshop-eksctl']].[AutoScalingGroupName, MinSize, MaxSize,DesiredCapacity]" \
    --output table
```

{{< output >}}
-----------------------------------------------------------------------
|                     DescribeAutoScalingGroups                       |
+-----------------------------------------------------+----+----+-----+
|  eks-nodegroup-1eb9b447-f3c1-0456-af77-af0bbd65bc9f |  3 |  3 |  3  |
+-----------------------------------------------------+----+----+-----+
{{< /output >}}

Now, increase the maximum capacity to 4 instances

```bash
# we need the ASG name
export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eksworkshop-eksctl']].AutoScalingGroupName" --output text)

# increase max capacity up to 4
aws autoscaling \
    update-auto-scaling-group \
    --auto-scaling-group-name ${ASG_NAME} \
    --min-size 3 \
    --desired-capacity 3 \
    --max-size 4

# Check new values
aws autoscaling \
    describe-auto-scaling-groups \
    --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eksworkshop-eksctl']].[AutoScalingGroupName, MinSize, MaxSize,DesiredCapacity]" \
    --output table
```
