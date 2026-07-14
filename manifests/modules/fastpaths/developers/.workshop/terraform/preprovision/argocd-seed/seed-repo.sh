#!/bin/bash

# Seed the catalog GitOps CodeCommit repository with the catalog manifests.
#
# Invoked by null_resource.eks_cap_argocd_repo_seed in argocd-capability.tf.
# Expects REPO_NAME, AWS_REGION, and SEED_DIR in the environment. Uses
# git-remote-codecommit (codecommit:: remote helper) so it authenticates with
# the ambient AWS credentials, with no SSH keys and no Git credential helper.
#
# Idempotent: clones the (possibly empty) repo, replaces the catalog/ tree with
# the seed manifests, and pushes only when the content differs. Re-running is a
# no-op when the repo already matches the seed.

set -Eeuo pipefail

: "${REPO_NAME:?REPO_NAME is required}"
: "${AWS_REGION:?AWS_REGION is required}"
: "${SEED_DIR:?SEED_DIR is required}"

if ! command -v git-remote-codecommit >/dev/null 2>&1 && ! python3 -c "import git_remote_codecommit" >/dev/null 2>&1; then
  echo "git-remote-codecommit is not installed; installing into a virtualenv..." >&2
  GRC_VENV="$(mktemp -d)/grc"
  python3 -m venv "$GRC_VENV"
  # shellcheck disable=SC1091
  source "$GRC_VENV/bin/activate"
  pip install --quiet git-remote-codecommit
fi

REMOTE="codecommit::${AWS_REGION}://${REPO_NAME}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

git clone --quiet "$REMOTE" "$WORKDIR" 2>/dev/null || {
  # Empty repository: git clone warns and returns non-zero. Initialize instead.
  git -C "$WORKDIR" init --quiet
  git -C "$WORKDIR" remote add origin "$REMOTE"
}

git -C "$WORKDIR" config user.email "eks-workshop@amazon.com"
git -C "$WORKDIR" config user.name "EKS Workshop"

# Replace the catalog tree wholesale so the seed is the source of truth.
rm -rf "${WORKDIR:?}/catalog"
mkdir -p "$WORKDIR/catalog"
cp -R "$SEED_DIR/." "$WORKDIR/catalog/"

git -C "$WORKDIR" add -A

if git -C "$WORKDIR" diff --cached --quiet 2>/dev/null; then
  echo "CodeCommit repo ${REPO_NAME} already up to date; nothing to seed."
  exit 0
fi

git -C "$WORKDIR" commit --quiet -m "Seed catalog manifests for Argo CD capability fast path"

# Ensure we push to a branch named main regardless of the local default.
CURRENT_BRANCH="$(git -C "$WORKDIR" rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  git -C "$WORKDIR" branch -M main
fi

git -C "$WORKDIR" push --quiet origin main
echo "Seeded CodeCommit repo ${REPO_NAME} (branch main) with catalog manifests."
