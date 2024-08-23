#!/bin/bash
# pod-failure.sh - Simulates pod failure using Chaos Mesh

# Generates a unique identifier for the pod failure experiment
unique_id=$(date +%s)

# Create a YAML configuration for the PodChaos resource
kubectl apply -f - <<EOF
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-$unique_id
  namespace: ui
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - ui
    labelSelectors:
      "app.kubernetes.io/name": "ui"
  duration: "60s"
EOF

# Apply the PodChaos configuration to simulate the failure
#kubectl apply -f pod-failure.yaml