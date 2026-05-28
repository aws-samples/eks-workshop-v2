#!/bin/bash

set -e

# Delete Gateway API resources BEFORE uninstalling the controller
# so the LBC can clean up the ALB and target groups
if kubectl api-resources --api-group=gateway.networking.k8s.io -o name 2>/dev/null | grep -q httproute; then
  kubectl delete httproute --all -A --ignore-not-found
  kubectl delete gateway --all -A --ignore-not-found --wait=false
  kubectl delete gatewayclass --all --ignore-not-found --wait=false
fi

# Delete AWS LBC Gateway CRDs resources
if kubectl api-resources --api-group=gateway.k8s.aws -o name 2>/dev/null | grep -q targetgroupconfiguration; then
  kubectl delete targetgroupconfiguration --all -A --ignore-not-found
  kubectl delete loadbalancerconfiguration --all -A --ignore-not-found
  kubectl delete listenerruleconfiguration --all -A --ignore-not-found
fi

# Wait for Gateways to be fully removed (finalizers cleared by LBC)
echo "Waiting for Gateway resources to be cleaned up..."
timeout 120 bash -c 'while kubectl get gateway -A 2>/dev/null | grep -q .; do sleep 5; done' || true

# Force-remove finalizers if still stuck
for gw in $(kubectl get gateway -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' 2>/dev/null); do
  ns=$(echo $gw | cut -d/ -f1)
  name=$(echo $gw | cut -d/ -f2)
  kubectl patch gateway $name -n $ns --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
done
kubectl delete gateway --all -A --ignore-not-found 2>/dev/null || true
kubectl delete gatewayclass --all --ignore-not-found 2>/dev/null || true

# Now uninstall the controllers
uninstall-helm-chart aws-load-balancer-controller kube-system

# Clean up CRDs
kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/config/crd/gateway/gateway-crds.yaml --ignore-not-found 2>/dev/null || true
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml --ignore-not-found 2>/dev/null || true
