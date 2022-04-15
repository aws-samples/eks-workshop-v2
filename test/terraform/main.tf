module "cluster" {
  source  = "../../terraform/cluster-only"

  id = var.cluster_id
}