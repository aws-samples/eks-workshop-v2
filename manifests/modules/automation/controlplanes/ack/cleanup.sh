#!/bin/bash

set -oux pipefail

kubectl delete -k /workspace/modules/ack/manifests/ || true
kubectl delete -k /workspace/modules/ack/rds/fieldexports || true
kubectl delete ns catalog-prod || true
kubectl delete -k /workspace/modules/ack/rds/k8s || true
kubectl delete -n default secret rds-eks-workshop || true
kubectl delete -k /workspace/modules/ack/ec2 || true
kubectl delete -k /workspace/modules/ack/rds/roles || true
helm uninstall -n ack-system ack-rds-controller || true
helm uninstall -n ack-system ack-ec2-controller || true
helm uninstall -n ack-system ack-iam-controller || true
kubectl delete namespace ack-system || true
aws iam delete-role-policy --role-name ack-iam-controller --policy-name ack-iam-recommended-policy || true
aws iam delete-role --role-name ack-iam-controller || true
