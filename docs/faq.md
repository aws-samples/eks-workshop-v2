# EKS Workshop - FAQ

### Q: When I create the infrastructure I get an error about the Kubecost helm chart

The error looks similar to this:

```
│ Error: could not download chart: failed to download "oci://public.ecr.aws/kubecost/cost-analyzer" at version "1.96.0"
│ 
│   with module.cluster.module.eks-blueprints-kubernetes-addons.module.kubecost[0].module.helm_addon.helm_release.addon[0],
│   on .terraform/modules/cluster.eks-blueprints-kubernetes-addons/modules/kubernetes-addons/helm-addon/main.tf line 1, in resource "helm_release" "addon":
│    1: resource "helm_release" "addon" {
│ 
╵
```

This is likely due to expired credentials from previously interacting with ECR Public. Run `docker logout` and then re-run `make create-infrastructure`.