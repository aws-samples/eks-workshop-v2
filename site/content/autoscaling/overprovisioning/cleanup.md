---
title: "Cleanup"
weight: 2
draft: false
---

To delete all the resources in this chapter execute the commands below

```bash
# Cleanup K8S resources
kubectl delete -f ~/environment/overprovision-lab/pause-deploy.yaml 
kubectl delete -f ~/environment/overprovision-lab/pause-priorityclass.yaml
kubectl delete -f ~/environment/overprovision-lab/default-priorityclass.yaml
rm -rf ~/environment/overprovision-lab

# Scale down application #TODO: Change after app
kubectl scale deployment --replicas=1 nginx

# Set ASG value to previous values
aws autoscaling \
    update-auto-scaling-group \
    --auto-scaling-group-name ${ASG_NAME} \
    --min-size 3 \
    --desired-capacity 3 \
    --max-size 3
```