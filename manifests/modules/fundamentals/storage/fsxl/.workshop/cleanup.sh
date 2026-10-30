# #!/bin/bash

# Anything user has created after prepare-environment

set -e

kubectl delete namespace ui --ignore-not-found=true

kubectl delete pv fsxl-pv --ignore-not-found=true

kubectl delete storageclass fsx-lustre-sc --ignore-not-found=true

aws eks delete-addon --cluster-name $EKS_CLUSTER_NAME --addon-name aws-fsx-csi-driver 2>/dev/null || true
