#!/bin/bash

set -e

# This lab pins the catalog Deployment to the spot nodegroup with a
# nodeSelector. Deleting the nodegroup (below) is asynchronous, so if catalog
# is still scheduled there its pods get terminated along with the nodes and race
# the environment reset's readiness wait, which then fails with a transient
# "pods ... not found". Move catalog back onto the default nodes and let it
# settle first so nothing base-app depends on the spot nodes when they go away.
kubectl -n catalog patch deployment catalog --type=json \
  -p '[{"op":"remove","path":"/spec/template/spec/nodeSelector"}]' 2>/dev/null || true
kubectl -n catalog rollout status deployment/catalog --timeout=150s 2>/dev/null || true

delete-nodegroup managed-spot
