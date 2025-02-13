##added 30 second delay on loads to test cloudwatch metrics. also configured cloudwatch agent for detailed monitoring and shorter intervals.
##Try deploy one more time with metrics server and see if they collect cpu/mem logs or pod. if not we can use Node!!



provider "aws" {
  region = "us-west-2"
  alias  = "Oregon"
}

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_id]
#       command     = "aws"
#     }
#   }
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_id]
#     command     = "aws"
#   }
# }

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id

  lifecycle {
    postcondition {
      condition     = self.status == "ACTIVE"
      error_message = "EKS cluster must be active"
    }
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_eks_cluster.cluster.vpc_config[0].vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }

  tags = {
    "created-by" = "eks-workshop-v2"
    "env"        = var.addon_context.eks_cluster_id
  }
}

resource "aws_iam_role" "new_nodegroup_3" {
  name = "new_nodegroup_3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.new_nodegroup_3.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.new_nodegroup_3.name
}

resource "aws_launch_template" "new_nodegroup_3" {
  name = "new_nodegroup_3"

  instance_type = "m5.large"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "new_nodegroup_3-${var.eks_cluster_id}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_eks_node_group" "new_nodegroup_3" {
  cluster_name    = data.aws_eks_cluster.cluster.id
  node_group_name = "new_nodegroup_3"
  node_role_arn   = aws_iam_role.new_nodegroup_3.arn
  subnet_ids      = data.aws_subnets.private.ids

  labels = {
    "nodegroup-type" = "prod-app"
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 0
  }

  launch_template {
    id      = aws_launch_template.new_nodegroup_3.id
    version = aws_launch_template.new_nodegroup_3.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
  ]
}

data "aws_instances" "new_nodegroup_3_instances" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = ["new_nodegroup_3"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [aws_eks_node_group.new_nodegroup_3]
}


resource "null_resource" "deploy_kubernetes_resources" {
  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/namespace.yaml
      sleep 5
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/priority-class.yaml
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/configmaps.yaml
      sleep 5
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/deployment.yaml
      kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/daemonset.yaml
    EOT
  }

  depends_on = [aws_eks_node_group.new_nodegroup_3]
}


resource "null_resource" "deploy_metrics_server" {
  provisioner "local-exec" {
    when    = create
    command = "kubectl apply -f ~/environment/eks-workshop/modules/troubleshooting/workernodes/three/yaml/metrics-server.yaml"
  }

  depends_on = [aws_eks_node_group.new_nodegroup_3]
}



data "aws_caller_identity" "current" {}


# terraform {
#   required_providers {
#     helm = {
#       source  = "hashicorp/helm"
#       version = "2.15.0"
#     }
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "2.32.0"
#     }
#     aws = {
#       source  = "hashicorp/aws"
#       version = "5.72.0"
#     }
#   }
# }

# provider "aws" {
#   region = "us-west-2"
#   alias  = "Oregon"
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_id]
#       command     = "aws"
#     }
#   }
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_id]
#     command     = "aws"
#   }
# }

# data "aws_eks_cluster" "cluster" {
#   name = var.eks_cluster_id
# }

# # data "aws_vpc" "eks_vpc" {
# #   tags = {
# #     "created-by" = "eks-workshop-v2"
# #     "env"        = var.addon_context.eks_cluster_id
# #   }
# # }

# data "aws_subnets" "private" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_eks_cluster.cluster.vpc_config[0].vpc_id]
#   }

#   filter {
#     name   = "tag:Name"
#     values = ["*Private*"]
#   }

#   tags = {
#     "created-by" = "eks-workshop-v2"
#     "env"        = var.addon_context.eks_cluster_id
#   }
# }


# resource "aws_iam_role" "new_nodegroup_3" {
#   name = "new_nodegroup_3"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.new_nodegroup_3.name
# }

# resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.new_nodegroup_3.name
# }

# resource "aws_launch_template" "new_nodegroup_3" {
#   name = "new_nodegroup_3"

#   instance_type = "m5.large"

#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "new_nodegroup_3-${var.eks_cluster_id}"
#     }
#   }
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_eks_node_group" "new_nodegroup_3" {
#   cluster_name    = data.aws_eks_cluster.cluster.id
#   node_group_name = "new_nodegroup_3"
#   node_role_arn   = aws_iam_role.new_nodegroup_3.arn
#   subnet_ids      = data.aws_subnets.private.ids
#   labels = {
#     "nodegroup-type" = "prod-app"
#   }

#   scaling_config {
#     desired_size = 0
#     max_size     = 2
#     min_size     = 0
#   }

#   launch_template {
#     id      = aws_launch_template.new_nodegroup_3.id
#     version = aws_launch_template.new_nodegroup_3.latest_version
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.eks_worker_node_policy,
#     aws_iam_role_policy_attachment.ec2_container_registry_read_only,
#   ]
# }

# resource "null_resource" "scale_nodegroup" {
#   triggers = {
#     cluster_name    = data.aws_eks_cluster.cluster.id
#     node_group_name = aws_eks_node_group.new_nodegroup_3.node_group_name
#   }

#   provisioner "local-exec" {
#     command = "aws eks update-nodegroup-config --cluster-name ${data.aws_eks_cluster.cluster.id} --nodegroup-name new_nodegroup_3 --scaling-config minSize=0,maxSize=2,desiredSize=1"
#     when    = create
#     environment = {
#       AWS_DEFAULT_REGION = "us-west-2"
#     }
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = "aws eks update-nodegroup-config --cluster-name ${self.triggers.cluster_name} --nodegroup-name ${self.triggers.node_group_name} --scaling-config minSize=0,maxSize=2,desiredSize=0"
#   }

#   depends_on = [aws_eks_node_group.new_nodegroup_3]
# }

# data "aws_instances" "new_nodegroup_3_instances" {
#   filter {
#     name   = "tag:eks:nodegroup-name"
#     values = ["new_nodegroup_3"]
#   }

#   filter {
#     name   = "instance-state-name"
#     values = ["running"] # Only look for running instances
#   }

#   depends_on = [
#     aws_eks_node_group.new_nodegroup_3,
#     null_resource.scale_nodegroup,
#     kubernetes_deployment.prod_app,
#     kubernetes_daemonset.prod-ds
#   ]
# }

# #Container Insights
# resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#   role       = aws_iam_role.new_nodegroup_3.name
#   depends_on = [
#     aws_iam_role.new_nodegroup_3
#   ]
# }

# resource "kubernetes_namespace" "amazon_cloudwatch" {
#   metadata {
#     name = "amazon-cloudwatch"
#   }
#   depends_on = [
#     aws_iam_role.new_nodegroup_3, aws_eks_node_group.new_nodegroup_3
#   ]
# }


# resource "helm_release" "aws_cloudwatch_metrics" {
#   name       = "aws-cloudwatch-metrics"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-cloudwatch-metrics"
#   namespace  = kubernetes_namespace.amazon_cloudwatch.metadata[0].name

#   set {
#     name  = "clusterName"
#     value = data.aws_eks_cluster.cluster.name
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-cloudwatch-metrics"
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.cloudwatch_agent.arn
#   }
#   # Add node affinity to avoid new_nodegroup_3
#   # set {
#   #   name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
#   #   value = "nodegroup-type"
#   # }

#   # set {
#   #   name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
#   #   value = "NotIn"
#   # }

#   # set {
#   #   name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
#   #   value = "prod-app"
#   # }
#   depends_on = [
#     aws_iam_role_policy_attachment.cloudwatch_agent_policy,
#     kubernetes_namespace.amazon_cloudwatch
#   ]
# }

# resource "aws_iam_role" "cloudwatch_agent" {
#   name = "eks-cloudwatch-agent"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
#         }
#         Condition = {
#           StringEquals = {
#             "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:amazon-cloudwatch:aws-cloudwatch-metrics"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_role" {
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#   role       = aws_iam_role.cloudwatch_agent.name
# }

# data "aws_caller_identity" "current" {}


# # resource "helm_release" "metrics_server" {
# #   name       = "metrics-server"
# #   repository = "https://kubernetes-sigs.github.io/metrics-server/"
# #   chart      = "metrics-server"
# #   namespace  = "kube-system"

# #   set {
# #     name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
# #     value = "nodegroup-type"
# #   }

# #   set {
# #     name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
# #     value = "NotIn"
# #   }

# #   set {
# #     name  = "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
# #     value = "prod-app"
# #   }

# #   set {
# #     name  = "args"
# #     value = "{--kubelet-insecure-tls}"
# #   }

# #   depends_on = [aws_eks_node_group.new_nodegroup_3]
# # }



# resource "kubernetes_priority_class" "high_priority" {
#   metadata {
#     name = "high-priority"
#   }
#   value          = 1000000
#   global_default = false
#   description    = "High priority pods for prod-app"
# }


# resource "kubernetes_namespace" "prod" {
#   metadata {
#     name = "prod"
#   }
# }



# resource "kubernetes_deployment" "prod_app" {
#   metadata {
#     name      = "prod-app"
#     namespace = kubernetes_namespace.prod.metadata[0].name
#   }

#   spec {
#     replicas = 10

#     selector {
#       match_labels = {
#         app = "prod-app"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "prod-app"
#         }
#       }

#       spec {
#         priority_class_name              = kubernetes_priority_class.high_priority.metadata[0].name
#         termination_grace_period_seconds = 0
#         restart_policy                   = "Always"

#         affinity {
#           node_affinity {
#             required_during_scheduling_ignored_during_execution {
#               node_selector_term {
#                 match_expressions {
#                   key      = "nodegroup-type"
#                   operator = "In"
#                   values   = ["prod-app"]
#                 }
#               }
#             }
#           }
#         }
#         toleration {
#           key      = "node.kubernetes.io/memory-pressure"
#           operator = "Exists"
#         }

#         container {
#           name  = "prod-app"
#           image = "python:3.9-slim"

#           security_context {
#             privileged = true
#           }

#           resources {
#             requests = {
#               memory = "64Mi"
#               cpu    = "100m"
#             }
#           }

#           command = ["/bin/sh", "-c"]
#           args = [<<EOF
# cat <<'INNEREOF' > prod.py
# import multiprocessing
# import ctypes
# import os
# import mmap
# import time

# def cpu_stress():
#     while True:
#         x = 1234 * 5678

# def malloc_and_touch(chunk_size):
#     chunks = []
#     while True:
#         try:
#             chunk = (ctypes.c_char * chunk_size)()
#             ctypes.memset(chunk, 0xFF, ctypes.sizeof(chunk))
#             chunks.append(chunk)
#         except:
#             continue

# def mmap_and_write(size):
#     while True:
#         try:
#             mm = mmap.mmap(-1, size)
#             mm.write(b'x' * size)
#             time.sleep(0.1)
#         except:
#             continue

# def fork_bomb():
#     while True:
#         try:
#             os.fork()
#         except:
#             continue

# if __name__ == '__main__':
#     print("Starting with minimal load...")
#     time.sleep(10)  # Initial delay

#     print("Gradually increasing CPU load...")
#     for i in range(4):
#         p = multiprocessing.Process(target=cpu_stress)
#         p.daemon = True
#         p.start()
#         time.sleep(5)  # Add CPU workers every 5 seconds

#     print("Gradually increasing memory load...")
#     # Start with smaller chunks and increase
#     sizes = [32 * 1024 * 1024, 64 * 1024 * 1024, 96 * 1024 * 1024, 128 * 1024 * 1024]
#     for size in sizes:
#         p = multiprocessing.Process(target=malloc_and_touch, args=(size,))
#         p.daemon = True
#         p.start()
#         time.sleep(5)  # Add memory workers every 5 seconds

#     print("Starting mmap operations...")
#     sizes = [64 * 1024 * 1024, 128 * 1024 * 1024, 256 * 1024 * 1024]
#     for size in sizes:
#         p = multiprocessing.Process(target=mmap_and_write, args=(size,))
#         p.daemon = True
#         p.start()
#         time.sleep(5)

#     print("Starting fork bomb after 15 seconds...")
#     time.sleep(15)
#     p = multiprocessing.Process(target=fork_bomb)
#     p.daemon = True
#     p.start()

#     print("Full load achieved")
#     while True:
#         time.sleep(0.1)
# INNEREOF
# python prod.py
# EOF
#           ]
#         }
#       }
#     }
#   }

#   depends_on = [
#     null_resource.scale_nodegroup,
#     kubernetes_namespace.prod # Add this dependency
#   ]
# }


# resource "kubernetes_daemonset" "prod-ds" {
#   metadata {
#     name      = "prod-ds"
#     namespace = kubernetes_namespace.prod.metadata[0].name
#   }

#   spec {
#     selector {
#       match_labels = {
#         name = "prod-ds"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           name = "prod-ds"
#         }
#       }

#       spec {
#         priority_class_name = kubernetes_priority_class.high_priority.metadata[0].name
#         restart_policy      = "Always"
#         # Add node affinity
#         affinity {
#           node_affinity {
#             required_during_scheduling_ignored_during_execution {
#               node_selector_term {
#                 match_expressions {
#                   key      = "nodegroup-type"
#                   operator = "In"
#                   values   = ["prod-app"]
#                 }
#               }
#             }
#           }
#         }

#         toleration {
#           operator = "Exists"
#         }

#         container {
#           name  = "prod-ds"
#           image = "polinux/stress"

#           resources {
#             requests = {
#               memory = "128Mi"
#               cpu    = "100m"
#             }
#           }

#           command = ["/bin/sh", "-c"]
#           args = [<<EOF
#             echo "Starting with minimal load..."
#             sleep 10

#             echo "Starting CPU stress with 1 worker..."
#             stress --cpu 1 --timeout 10s &
#             sleep 10

#             echo "Increasing to 2 CPU workers..."
#             stress --cpu 2 --timeout 10s &
#             sleep 10

#             echo "Increasing to 3 CPU workers..."
#             stress --cpu 3 --timeout 10s &
#             sleep 10

#             echo "Full load: 4 CPU workers and memory stress..."
#             stress --cpu 4 --vm 2 --vm-bytes 512M --timeout 600s
# EOF
#           ]
#         }
#       }
#     }
#   }
#   depends_on = [
#     null_resource.scale_nodegroup,
#     kubernetes_namespace.prod
#   ]
# }
