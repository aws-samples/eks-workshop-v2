#!/bin/bash

set -Eeuo pipefail

# The EKS capability, IAM Capability Role, and DynamoDB IAM policies are
# tracked by the shared fastpaths preprovision Terraform and are torn down
# only when the entire fastpaths environment is destroyed. This script
# cleans up the per-lab resources the *learner* applied during the labs so
# the path can be entered/exited cleanly between sessions.

# --- Lab 1 (ACK) -------------------------------------------------------------

logmessage "Deleting ACK Table custom resources..."
delete-all-if-crd-exists tables.dynamodb.services.k8s.aws

logmessage "Removing carts Pod Identity association..."
for assoc in $(aws eks list-pod-identity-associations \
  --cluster-name "${EKS_CLUSTER_AUTO_NAME:-eks-workshop-auto}" \
  --namespace carts --service-account carts \
  --query 'associations[].associationId' --output text 2>/dev/null); do
  aws eks delete-pod-identity-association \
    --cluster-name "${EKS_CLUSTER_AUTO_NAME:-eks-workshop-auto}" \
    --association-id "$assoc" >/dev/null 2>&1 || true
done

logmessage "Restoring base-application carts ConfigMap..."
kubectl apply -k ~/environment/eks-workshop/base-application/carts >/dev/null 2>&1 || true

# --- Lab 2 (Argo CD) ---------------------------------------------------------

# Remove the catalog Application first so Argo CD stops reconciling, then let it
# prune the resources it owns (cascade=foreground waits for that to finish).
if kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
  if kubectl get application catalog -n argocd >/dev/null 2>&1; then
    logmessage "Deleting Argo CD catalog Application..."
    kubectl delete application catalog -n argocd \
      --cascade=foreground --timeout=180s >/dev/null 2>&1 || true
  fi

  # Remove the cluster registration Secret the learner created.
  if kubectl get secret eks-workshop -n argocd >/dev/null 2>&1; then
    logmessage "Removing Argo CD cluster registration..."
    kubectl delete secret eks-workshop -n argocd >/dev/null 2>&1 || true
  fi
fi

# The Application's prune may have removed the catalog namespace. Restore the
# base-application catalog so subsequent labs see a healthy retail store.
logmessage "Restoring base-application catalog..."
kubectl apply -k ~/environment/eks-workshop/base-application/catalog >/dev/null 2>&1 || true

# Remove the cloned GitOps working copy from the IDE home, if present.
rm -rf ~/environment/catalog-gitops >/dev/null 2>&1 || true

# Reset the CodeCommit repo back to the seeded state so the GitOps update step
# in Lab 2 always has the same starting tag (1.2.1) — without this, a re-run of
# `prepare-environment` finds a learner-pushed `1.2.2` commit still on main and
# the lab's `sed 1.2.1 → 1.2.2` becomes a no-op.
#
# This cleanup hook runs BEFORE the workshop-env.bash file is regenerated, so
# EKS_CAP_CODECOMMIT_REPO is not yet exported. The repo name is deterministic
# per the terraform: `${cluster_auto}-catalog-gitops`. Derive it.
CODECOMMIT_REPO="${EKS_CAP_CODECOMMIT_REPO:-${EKS_CLUSTER_AUTO_NAME:-eks-workshop-auto}-catalog-gitops}"

if aws codecommit get-repository --repository-name "$CODECOMMIT_REPO" >/dev/null 2>&1; then
  logmessage "Resetting CodeCommit repo ${CODECOMMIT_REPO} to seeded state..."
  SEED_DIR="/eks-workshop/manifests/modules/fastpaths/developers/.workshop/terraform/preprovision/argocd-seed/catalog"
  if [ -d "$SEED_DIR" ]; then
    WORKDIR="$(mktemp -d)"
    REMOTE="codecommit::${AWS_REGION}://${CODECOMMIT_REPO}"
    if git clone --quiet "$REMOTE" "$WORKDIR" 2>/dev/null; then
      git -C "$WORKDIR" config user.email "eks-workshop@amazon.com"
      git -C "$WORKDIR" config user.name "EKS Workshop"
      rm -rf "${WORKDIR:?}/catalog"
      mkdir -p "$WORKDIR/catalog"
      cp -R "$SEED_DIR/." "$WORKDIR/catalog/"
      git -C "$WORKDIR" add -A
      if ! git -C "$WORKDIR" diff --cached --quiet 2>/dev/null; then
        git -C "$WORKDIR" commit --quiet -m "Reset catalog manifests to seed state" || true
        git -C "$WORKDIR" push --quiet origin main >/dev/null 2>&1 || true
      fi
    fi
    rm -rf "$WORKDIR"
  fi
fi

# After the repo reset, force Argo CD to re-reconcile so the catalog Application
# applies the freshly-reset 1.2.1 manifests against the cluster (otherwise the
# Application thinks it's already Synced because it reconciled to the previous
# state, and the lab page sees a stale Deployment image).
if kubectl get application catalog -n argocd >/dev/null 2>&1; then
  logmessage "Forcing Argo CD catalog Application to re-sync..."
  kubectl annotate application catalog -n argocd \
    argocd.argoproj.io/refresh=hard --overwrite >/dev/null 2>&1 || true
fi

# --- Lab 3 (kro) -------------------------------------------------------------

# Order matters: delete the CartsStack instance first so kro prunes its
# children (Namespace, ACK Table, ConfigMap, ServiceAccount), then the RGD,
# then anything kro didn't manage. Without this order the RGD delete
# orphans the instance and the ACK Table never gets deleted.
if kubectl get crd cartsstacks.kro.run >/dev/null 2>&1; then
  if kubectl get cartsstack carts-kro -n default >/dev/null 2>&1; then
    logmessage "Deleting kro CartsStack instance carts-kro..."
    # Generous timeout: kro must prune the carts Deployment (Pod terminates),
    # the ACK Table (controller deletes the AWS DynamoDB table), and the
    # rest of the namespace's child resources before the instance disappears.
    kubectl delete cartsstack carts-kro -n default \
      --cascade=foreground --timeout=480s >/dev/null 2>&1 || true
  fi
fi

if kubectl get crd resourcegraphdefinitions.kro.run >/dev/null 2>&1; then
  if kubectl get rgd cartsstack >/dev/null 2>&1; then
    logmessage "Deleting kro ResourceGraphDefinition cartsstack..."
    kubectl delete rgd cartsstack --timeout=120s >/dev/null 2>&1 || true
  fi
fi

# Belt-and-braces: if the instance pruning didn't drop the namespace (e.g.
# kro was in a degraded state), remove it explicitly.
logmessage "Removing carts-kro namespace if present..."
kubectl delete ns carts-kro --ignore-not-found --timeout=120s >/dev/null 2>&1 || true

logmessage "Restoring ui Deployment carts endpoint (in case the optional UI demo overrode it)..."
# `kubectl set env -` removes the env var, restoring the Pod's compiled-in
# default (carts.carts:80). Idempotent — succeeds whether the override was
# applied or not.
kubectl -n ui set env deployment/ui RETAIL_UI_ENDPOINTS_CARTS_URL- >/dev/null 2>&1 || true

logmessage "Removing carts-kro Pod Identity association..."
for assoc in $(aws eks list-pod-identity-associations \
  --cluster-name "${EKS_CLUSTER_AUTO_NAME:-eks-workshop-auto}" \
  --namespace carts-kro --service-account carts \
  --query 'associations[].associationId' --output text 2>/dev/null); do
  aws eks delete-pod-identity-association \
    --cluster-name "${EKS_CLUSTER_AUTO_NAME:-eks-workshop-auto}" \
    --association-id "$assoc" >/dev/null 2>&1 || true
done
