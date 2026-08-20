#!/bin/bash

# Runs before Terraform destroys the Amazon EKS Capability for Argo CD, and the
# order matters: the Argo CD custom resources have to go first. They carry
# resources-finalizer.argocd.argoproj.io, and once the capability is gone nothing
# can clear that finalizer, so anything left behind wedges itself and its namespace
# in Terminating.
#
# Deliberately no `set -e`. reset-environment runs this hook without `|| true`, so
# a non-zero exit here aborts the participant's next lab. Every step therefore
# tolerates the resources not existing, which is the normal case when the lab was
# only partly completed.

logmessage "Deleting Argo CD applications..."

argocd_crds="applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io"

# Child applications first, then the parent, then the projects they belong to.
for crd in $argocd_crds; do
  kubectl get crd "$crd" &>/dev/null || continue

  # Clear resources-finalizer.argocd.argoproj.io before deleting. The namespaces are
  # deleted outright below, so there is nothing left for Argo CD to prune, and a
  # finalizer that nobody reconciles — an unhealthy capability, or one already
  # destroyed by a previous run — would otherwise block the delete for ever.
  #
  # Note kubectl patch has no --all-namespaces flag, so walk the objects and patch
  # each one in its own namespace. A merge patch with null is a no-op when the
  # finalizer is already absent.
  kubectl get "$crd" -A \
    -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' \
    2>/dev/null | while read -r ns name; do
    [ -n "$name" ] || continue
    kubectl patch "$crd" "$name" -n "$ns" --type=merge \
      -p '{"metadata":{"finalizers":null}}' &>/dev/null || true
  done

  # kubectl delete waits indefinitely by default, so ask for no wait and bound it
  # separately rather than risk hanging the participant's next lab.
  kubectl delete "$crd" -A --all --ignore-not-found --wait=false &>/dev/null || true
  kubectl wait --for=delete "$crd" -A --all --timeout=120s &>/dev/null || true
done

rm -rf ~/environment/argocd

# Argo CD creates these namespaces itself through CreateNamespace=true and does not
# label them, so the label selector below cannot see them. `argocd` is the
# capability's own namespace for the custom resources above.
kubectl delete namespace argocd carts catalog checkout orders ui \
  --ignore-not-found --timeout=180s || true

kubectl delete namespace -l app.kubernetes.io/created-by=eks-workshop \
  --timeout=180s || true
