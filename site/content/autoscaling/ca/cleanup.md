---
title: "Cleanup Scaling"
date: 2018-08-07T08:30:11-07:00
weight: 50
---

```bash
kubectl delete -f ~/environment/cluster-autoscaler/nginx.yaml

export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eksworkshop-eksctl']].AutoScalingGroupName" --output text)

aws autoscaling \
  update-auto-scaling-group \
  --auto-scaling-group-name ${ASG_NAME} \
  --min-size 3 \
  --desired-capacity 3 \
  --max-size 3

unset ASG_NAME
```
