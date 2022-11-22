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

### Q: Destroying my infrastructure failed and now I have AWS resources left over, what can I do?

All the AWS resources in the workshop are tagged, so you can find them like so:

```
aws resourcegroupstaggingapi get-resources \
    --tag-filters Key=created-by,Values=eks-workshop-v2 \
    --output json
```

You will need to clear these up manually.