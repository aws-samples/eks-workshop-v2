#!/bin/bash

set -e

# This lab pins the catalog Deployment to the spot nodegroup with a
# nodeSelector. Deleting the nodegroup (below) is asynchronous, so if catalog
# is still scheduled there its pods get terminated along with the nodes and race
# the environment reset's readiness wait, which then fails with a transient
# "pods ... not found". Move catalog back onto the default nodes and let it
# settle first so nothing base-app depends on the spot nodes when they go away.
#
# A merge patch rather than a JSON-patch `remove`, which errors when the path is
# already absent and would need its output discarded to stay quiet. Guarding on
# the Deployment existing keeps this a no-op on a second run (the hook also runs
# when a participant has deleted the namespace) without hiding real failures.
if kubectl -n catalog get deployment catalog >/dev/null 2>&1; then
  kubectl -n catalog patch deployment catalog --type=merge \
    -p '{"spec":{"template":{"spec":{"nodeSelector":null}}}}'
  kubectl -n catalog rollout status deployment/catalog --timeout=150s || true
fi

delete-nodegroup managed-spot
