#!/usr/bin/env bash
# Bump the Kubernetes version the workshop provisions.
#
# Usage: hack/upgrade-k8s.sh <k8s-patch> [eksctl-version]
#   e.g. hack/upgrade-k8s.sh 1.35.8 0.230.0
#
# The eksctl version is resolved from GitHub when omitted. Everything else that is
# tied to the Kubernetes version -- the node AMI release, the VPC CNI addon and the
# Cluster Autoscaler image -- is read from the EKS, SSM and GitHub APIs rather than
# guessed, so AWS credentials are required.
#
# Every edit is verified. An earlier version of this script targeted Terraform by
# line number and matched the wrong quote style in the Docusaurus config, so those
# edits silently did nothing while the script still exited 0. Anything that fails to
# match is now reported and makes the run fail.

set -euo pipefail

if [ $# -lt 1 ]; then
  cat >&2 <<'USAGE'
Usage: hack/upgrade-k8s.sh <k8s-patch> [eksctl-version]
   e.g. hack/upgrade-k8s.sh 1.35.8 0.230.0

Check which versions EKS currently offers, and when they leave standard support:
   aws eks describe-cluster-versions \
     --query 'clusterVersions[].[clusterVersion,endOfStandardSupportDate,defaultVersion]' \
     --output table
USAGE
  exit 1
fi

K8S_PATCH=$1        # 1.35.8
K8S=${K8S_PATCH%.*} # 1.35

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$SCRIPT_DIR/.."

for tool in aws yq curl python3; do
  command -v "$tool" > /dev/null || { echo "Error: $tool is required" >&2; exit 1; }
done

if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "Error: AWS credentials are needed to resolve the AMI and addon versions." >&2
  exit 1
fi

failed=0

# Applies a sed expression, then confirms the file ends up holding the value we
# wanted. Judging success by "did the file change" would be wrong twice over: it
# reports a failure when the value is already correct, which happens on any re-run,
# and it cannot tell a drifted pattern from an already-applied one. Writes through a
# temporary file because BSD and GNU sed disagree about the argument to -i.
edit() {
  local file=$1 expression=$2 expected=$3 description=$4
  if [ ! -f "$file" ]; then
    echo "  MISS  $description -- $file does not exist"
    failed=1
    return
  fi
  sed "$expression" "$file" > "$file.upgrade-tmp" && mv "$file.upgrade-tmp" "$file"
  if grep -qF "$expected" "$file"; then
    echo "  ok    $description"
  else
    echo "  MISS  $description -- '$expected' not present in $file after edit"
    failed=1
  fi
}

# Rewrites the default of one Terraform variable. Scoped to the variable's own block
# so it cannot hit a same-shaped default elsewhere in the file, and without the line
# numbers the previous version relied on.
set_tf_default() {
  local file=$1 variable=$2 value=$3 description=$4
  awk -v want="$variable" -v val="$value" '
    $0 ~ "^variable \"" want "\" *\\{" { inblock = 1 }
    inblock && /^[[:space:]]*default[[:space:]]*=/ {
      sub(/=.*/, "= \"" val "\""); inblock = 0; changed = 1
    }
    inblock && /^\}/ { inblock = 0 }
    { print }
    END { exit(changed ? 0 : 1) }
  ' "$file" > "$file.upgrade-tmp" && rc=0 || rc=$?
  if [ "$rc" -ne 0 ]; then
    rm -f "$file.upgrade-tmp"
    echo "  MISS  $description -- no default found for variable \"$variable\""
    failed=1
  else
    mv "$file.upgrade-tmp" "$file"
    echo "  ok    $description"
  fi
}

# Confirms a yq edit landed, since yq exits 0 whether or not the path existed.
set_yaml() {
  local file=$1 path=$2 value=$3 description=$4
  yq -i "$path = \"$value\"" "$file"
  if [ "$(yq "$path" "$file")" = "$value" ]; then
    echo "  ok    $description"
  else
    echo "  MISS  $description -- $path not set in $file"
    failed=1
  fi
}

echo "Resolving versions for Kubernetes $K8S ..."

# The recommended release_version parameter is already in the exact form eksctl and
# the Terraform node group want, which is why this replaces the old
# describe-images call -- that one picked Images[1] out of an unsorted list.
AMI_RELEASE=$(aws ssm get-parameter \
  --name "/aws/service/eks/optimized-ami/$K8S/amazon-linux-2023/x86_64/standard/recommended/release_version" \
  --query 'Parameter.Value' --output text 2> /dev/null || true)
if [ -z "$AMI_RELEASE" ] || [ "$AMI_RELEASE" = "None" ]; then
  echo "Error: no recommended AL2023 AMI for Kubernetes $K8S. Is that version released?" >&2
  exit 1
fi

VPC_CNI=$(aws eks describe-addon-versions --kubernetes-version "$K8S" --addon-name vpc-cni \
  --query 'addons[0].addonVersions[?compatibilities[0].defaultVersion==`true`].addonVersion' \
  --output text 2> /dev/null | head -1 || true)

# Cluster Autoscaler is released in lockstep with Kubernetes, so the image tag has
# to follow the cluster's minor version or the autoscaling lab breaks.
CA_VERSION=$(curl -sf "https://api.github.com/repos/kubernetes/autoscaler/releases?per_page=100" \
  | python3 -c "
import json,sys
tags=[r['tag_name'].removeprefix('cluster-autoscaler-')
      for r in json.load(sys.stdin)
      if r.get('tag_name','').startswith('cluster-autoscaler-$K8S.')]
print(tags[0] if tags else '')
" 2> /dev/null || true)

if [ $# -ge 2 ]; then
  EKSCTL=$2
else
  EKSCTL=$(curl -sf https://api.github.com/repos/eksctl-io/eksctl/releases/latest \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'].lstrip('v'))" 2> /dev/null || true)
  [ -z "$EKSCTL" ] && { echo "Error: could not resolve the latest eksctl; pass it explicitly" >&2; exit 1; }
fi

cat <<SUMMARY

  kubernetes        $K8S (kubectl v$K8S_PATCH)
  node AMI release  $AMI_RELEASE
  vpc-cni addon     ${VPC_CNI:-<unresolved, left unchanged>}
  cluster-autoscaler ${CA_VERSION:-<unresolved, left unchanged>}
  eksctl            $EKSCTL

SUMMARY

echo "Editing files ..."

# Both clusters move together. The Auto Mode cluster was missed entirely before,
# which left the fastpath labs on the old version.
set_yaml cluster/eksctl/cluster.yaml '.metadata.version' "$K8S" "cluster.yaml version"
set_yaml cluster/eksctl/cluster.yaml '.managedNodeGroups[0].releaseVersion' "$AMI_RELEASE" "cluster.yaml node AMI"
set_yaml cluster/eksctl/cluster-auto.yaml '.metadata.version' "$K8S" "cluster-auto.yaml version"

if [ -n "$VPC_CNI" ]; then
  set_yaml cluster/eksctl/cluster.yaml '.addons[0].version' "$VPC_CNI" "cluster.yaml vpc-cni addon"
fi

set_tf_default cluster/terraform/variables.tf cluster_version "$K8S" "terraform cluster_version"
set_tf_default cluster/terraform/variables.tf ami_release_version "$AMI_RELEASE" "terraform ami_release_version"

if [ -n "$CA_VERSION" ]; then
  set_tf_default \
    manifests/modules/autoscaling/compute/cluster-autoscaler/.workshop/terraform/vars.tf \
    cluster_autoscaler_version "$CA_VERSION" "cluster-autoscaler image"
fi

edit lab/scripts/installer.sh \
  "s/kubectl_version='.*'/kubectl_version='$K8S_PATCH'/" \
  "kubectl_version='$K8S_PATCH'" "installer.sh kubectl"
edit lab/scripts/installer.sh \
  "s/eksctl_version='.*'/eksctl_version='$EKSCTL'/" \
  "eksctl_version='$EKSCTL'" "installer.sh eksctl"
edit hack/lib/kubectl-version.sh \
  "s/KUBECTL_VERSION='.*'/KUBECTL_VERSION='v$K8S_PATCH'/" \
  "KUBECTL_VERSION='v$K8S_PATCH'" "kubectl-version.sh"

# Double quotes, which is what the file actually uses -- the previous version
# matched single quotes and so never changed anything here.
edit website/docusaurus.config.js \
  "s/KUBERNETES_VERSION: \".*\"/KUBERNETES_VERSION: \"$K8S\"/" \
  "KUBERNETES_VERSION: \"$K8S\"" "docs KUBERNETES_VERSION"

echo
if [ "$failed" -ne 0 ]; then
  echo "Some edits did not apply. Fix the patterns above before committing." >&2
  exit 1
fi

samples=$(grep -rl "eks-" website/docs website/i18n --include=*.md 2> /dev/null \
  | xargs grep -l "v1\.[0-9]*\.[0-9]*-eks-" 2> /dev/null | wc -l | tr -d ' ')

AMI_ID=$(aws ssm get-parameter \
  --name "/aws/service/eks/optimized-ami/$K8S/amazon-linux-2023/x86_64/standard/recommended/image_id" \
  --query 'Parameter.Value' --output text 2> /dev/null || echo '<lookup failed>')

cat <<NEXT
Done. Two things this cannot resolve on its own:

1. KUBERNETES_NODE_VERSION in website/docusaurus.config.js still reads
   $(grep -o 'KUBERNETES_NODE_VERSION: "[^"]*"' website/docusaurus.config.js || echo '<not found>')
   This is the kubelet build stamp that appears in the VERSION column of the
   kubectl get nodes samples, and nothing publishes it: the SSM path for this AMI
   exposes only image_id, image_name, release_version and schema_version, the AMI
   description stops at the patch version, and it is absent from the AMI release
   notes. It lives in the kubelet binary, so read it from a node on $K8S:
     kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}'
   Or, without waiting for a cluster, from the AMI itself ($AMI_ID) --
   launch one throwaway instance with an SSM-capable instance profile and run:
     kubelet --version

2. $samples doc files contain sample output with an older v1.x-eks-<hash>. Those are
   illustrative and are left alone; refresh them if the drift matters:
     grep -rln "v1\.[0-9]*\.[0-9]*-eks-" website/docs website/i18n

Then verify, paying attention to the labs most sensitive to a minor bump:
   make create-environment
   make test module=autoscaling
   make test module=fastpaths
NEXT

if [ -n "$VPC_CNI" ]; then
  cat <<'CNI'

Note: the vpc-cni addon version was bumped with the cluster. Sanity-check the labs
that depend on CNI behaviour -- network policies, security groups for pods, prefix
delegation and custom networking.
CNI
fi
