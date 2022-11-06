#!/bin/bash

set -oux pipefail

kubectl delete -k /workspace/modules/ack/manifests/
kubectl delete -n default fieldexports.services.k8s.aws --all
kubectl delete -n default brokers.mq.services.k8s.aws --all
kubectl delete -n default dbinstances.rds.services.k8s.aws --all
kubectl delete -n default dbsubnetgroups.rds.services.k8s.aws --all
kubectl delete -n default securitygroup.ec2.services.k8s.aws --all
kubectl delete -n default secret rds-eks-workshop
kubectl delete -n default secret mq-eks-workshop
kubectl delete -n ack-system roles.iam.services.k8s.aws  --all
kubectl delete -n ack-system policies.iam.services.k8s.aws --all
helm uninstall -n ack-system ack-rds-controller
helm uninstall -n ack-system ack-mq-controller
helm uninstall -n ack-system ack-ec2-controller
helm uninstall -n ack-system ack-iam-controller
aws iam delete-role-policy --role-name ack-iam-controller --policy-name ack-iam-recommended-policy
aws iam delete-role --role-name ack-iam-controller
exit 0