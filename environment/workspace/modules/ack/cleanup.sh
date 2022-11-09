#!/bin/bash

set -oux pipefail

kubectl delete -k /workspace/modules/ack/manifests/
kubectl delete -k /workspace/modules/ack/mq/fieldexports
kubectl delete -k /workspace/modules/ack/rds/fieldexports
kubectl delete -k /workspace/modules/ack/mq/k8s/broker
kubectl delete -k /workspace/modules/ack/mq/k8s/security-group
kubectl delete -k /workspace/modules/ack/rds/k8s
kubectl delete -n default secret rds-eks-workshop
kubectl delete -n default secret mq-eks-workshop
kubectl delete -k /workspace/modules/ack/ec2
kubectl delete -k /workspace/modules/ack/rds/roles
kubectl delete -k /workspace/modules/ack/mq/roles
helm uninstall -n ack-system ack-rds-controller
helm uninstall -n ack-system ack-mq-controller
helm uninstall -n ack-system ack-ec2-controller
helm uninstall -n ack-system ack-iam-controller
kubectl delete namespace ack-system
aws iam delete-role-policy --role-name ack-iam-controller --policy-name ack-iam-recommended-policy
aws iam delete-role --role-name ack-iam-controller
