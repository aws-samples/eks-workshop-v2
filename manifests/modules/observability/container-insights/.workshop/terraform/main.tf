data "aws_region" "current" {}

# The EKS Pod Identity Agent is a prerequisite for granting the CloudWatch agent
# permissions via EKS Pod Identity, which the learner sets up in the lab. OVERWRITE lets
# Terraform adopt the add-on if it is already present on the cluster.
resource "aws_eks_addon" "pod_identity" {
  cluster_name                = var.addon_context.eks_cluster_id
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  preserve                    = false
}

resource "aws_cloudwatch_dashboard" "order_metrics_ci" {
  dashboard_name = "Order-Service-Metrics-1"

  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 6,
          "width" : 6,
          "y" : 0,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [{ "expression" : "SELECT COUNT(watch_orders_total) FROM \"ContainerInsights/Prometheus\" WHERE productId != '*' GROUP BY productId", "id" : "q1", "region" : data.aws_region.current.name }]
            ],
            "view" : "pie",
            "region" : data.aws_region.current.name,
            "title" : "Orders by ProductId",
            "period" : 300,
            "stat" : "Average"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 0,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "sparkline" : true,
            "view" : "singleValue",
            "metrics" : [
              [{ "expression" : "SELECT SUM(watch_orders_total) FROM \"ContainerInsights/Prometheus\" WHERE productId = '*'", "label" : "Total", "id" : "q1" }]
            ],
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "period" : 300,
            "title" : "Order Count"
          }
        }
      ]
  })
}
