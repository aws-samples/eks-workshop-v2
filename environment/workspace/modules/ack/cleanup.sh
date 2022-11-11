#!/bin/bash

set -oux pipefail

kubectl delete -k /workspace/modules/ack/manifests/ || true
kubectl delete -k /workspace/modules/ack/mq/fieldexports || true
kubectl delete -k /workspace/modules/ack/rds/fieldexports || true
kubectl delete -k /workspace/modules/ack/mq/k8s/broker || true
kubectl delete -k /workspace/modules/ack/mq/k8s/security-group || true
kubectl delete -k /workspace/modules/ack/rds/k8s || true
kubectl delete -n default secret rds-eks-workshop || true
kubectl delete -n default secret mq-eks-workshop || true
kubectl delete -k /workspace/modules/ack/ec2 || true
kubectl delete -k /workspace/modules/ack/rds/roles || true
kubectl delete -k /workspace/modules/ack/mq/roles || true
helm uninstall -n ack-system ack-rds-controller || true
helm uninstall -n ack-system ack-mq-controller || true
helm uninstall -n ack-system ack-ec2-controller || true
helm uninstall -n ack-system ack-iam-controller || true
kubectl delete namespace ack-system || true
aws iam delete-role-policy --role-name ack-iam-controller --policy-name ack-iam-recommended-policy || true
aws iam delete-role --role-name ack-iam-controller || true
