##To do - added nodegroup name as variable and change change to use the variable instead.


terraform {
  required_providers {
    #    kubectl = {
    #      source  = "gavinbunney/kubectl"
    #      version = ">= 1.14"
    #    }
  }
}


provider "aws" {
  region = "us-west-2"
  alias  = "Oregon"
}

/* locals {
  tags = {
    module = "troubleshooting"
  }
}
 */
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_id
}

data "aws_subnets" "private" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
  filter {
    name   = "tag:Name"
    values = ["*Private*"]
  }
}


#creating IAM role for SSM access
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

#attaching all needed policies including ssm

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.new_nodegroup_3.name
}

# resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.new_nodegroup_3.name
# }

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.new_nodegroup_3.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.new_nodegroup_3.name
}

# Create a new launch template to add ec2 names
resource "aws_launch_template" "new_launch_template" {
  name = "new_nodegroup_3"

  instance_type = "m5.large"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "troubleshooting-three-${var.eks_cluster_id}"
    }
  }
  lifecycle {
    create_before_destroy = true
  }

}


#Create New nodegroup with launch template
resource "aws_eks_node_group" "new_nodegroup_3" {
  cluster_name    = data.aws_eks_cluster.cluster.id
  node_group_name = "new_nodegroup_3"
  node_role_arn   = aws_iam_role.new_nodegroup_3.arn
  subnet_ids      = data.aws_subnets.private.ids

  scaling_config {
    desired_size = 0
    max_size     = 2
    min_size     = 0
  }

  launch_template {
    id      = aws_launch_template.new_launch_template.id
    version = aws_launch_template.new_launch_template.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    #aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.ssm_managed_instance_core,
  ]
}

# ###modify aws-auth and reboot instance (have to create a script to make sure aws-auth node arn is 
# # fixed before evicting or else pod termination will get stuck)
# resource "null_resource" "modify_aws_auth_and_reboot" {
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = <<-EOT
#       echo "Waiting for 75 seconds before modifying aws-auth..."
#       sleep 90

#       # Get the current aws-auth ConfigMap
#       kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml

#       # Use sed to modify the specific role mapping
#       # The role ARN is escaped to handle special characters
#       sed -i 's|rolearn: ${replace(aws_iam_role.new_nodegroup_3.arn, "/", "\\/")}|rolearn: ${replace(replace(aws_iam_role.new_nodegroup_3.arn, "role/", "role/x"), "/", "\\/")}|' aws-auth-temp.yaml

#       # Apply the modified ConfigMap
#       kubectl apply -f aws-auth-temp.yaml

#       # Clean up the temporary file
#       rm aws-auth-temp.yaml

#       echo "Waiting for another 10 seconds before rebooting the instance..."
#       sleep 5

#       # Find the instance ID of the running node in the new node group
#       INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:eks:nodegroup-name,Values=new_nodegroup_3" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text)

#       if [ -n "$INSTANCE_ID" ]; then
#         echo "Found instance ID: $INSTANCE_ID. Rebooting..."
#         aws ec2 reboot-instances --instance-ids $INSTANCE_ID
#         echo "Reboot command sent for instance $INSTANCE_ID"
#       else
#         echo "No running instances found in the new_nodegroup_3 node group"
#       fi
#     EOT

#     environment = {
#       KUBECONFIG         = "/home/ec2-user/.kube/config"
#       AWS_DEFAULT_REGION = "us-west-2" # Replace with your AWS region
#     }
#   }

#   depends_on = [null_resource.increase_desired_count, aws_eks_node_group.new_nodegroup_3]
# }





resource "null_resource" "increase_desired_count" {
  #trigger to properly capture the cluster and node group names for both create and destroy operations
  triggers = {
    cluster_name    = data.aws_eks_cluster.cluster.id
    node_group_name = aws_eks_node_group.new_nodegroup_3.node_group_name
  }
  provisioner "local-exec" {
    command = "aws eks update-nodegroup-config --cluster-name ${data.aws_eks_cluster.cluster.id} --nodegroup-name new_nodegroup_3 --scaling-config minSize=0,maxSize=2,desiredSize=1"
    when    = create
    environment = {
      AWS_DEFAULT_REGION = "us-west-2" # Replace with any region
    }
    #This will eventually transition newnodegroup into Degraded state. Need to find out how to bring it back to healthy state.
  }
  provisioner "local-exec" {
    when    = destroy
    command = "aws eks update-nodegroup-config --cluster-name ${self.triggers.cluster_name} --nodegroup-name ${self.triggers.node_group_name} --scaling-config minSize=0,maxSize=2,desiredSize=0"
  }
  depends_on = [aws_eks_node_group.new_nodegroup_3]
}


resource "null_resource" "modify_aws_auth_and_reboot" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Waiting for a new node to appear..."
      while true; do
        NODE_INFO=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{range .items[*]}{.metadata.name} {.spec.providerID}{"\n"}{end}' | head -n 1)
        if [ -n "$NODE_INFO" ]; then
          NODE_NAME=$(echo $NODE_INFO | cut -d' ' -f1)
          INSTANCE_ID=$(echo $NODE_INFO | cut -d' ' -f2 | cut -d'/' -f5)
          echo "Found a new node: $NODE_NAME with Instance ID: $INSTANCE_ID"
          break
        fi
        echo "No new nodes found yet. Waiting 5 seconds..."
        sleep 5
      done

      echo "Adding taint to prevent non-DaemonSet pods from being scheduled..."
      kubectl taint nodes $NODE_NAME dedicated=experimental:NoSchedule

      echo "Waiting for the node to be in Ready state..."
      while true; do
        if kubectl get nodes $NODE_NAME -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
          echo "Node $NODE_NAME is now Ready"
          break
        fi
        echo "Node not Ready yet. Waiting 5 seconds..."
        sleep 5
      done

      echo "Creating new aws-auth ConfigMap with incorrect role syntax..."
      # Get the original role ARN
      ROLE_ARN="${aws_iam_role.new_nodegroup_3.arn}"
      # Modify the role ARN to include 'x' immediately after 'role/'
      MODIFIED_ROLE_ARN=$(echo "$ROLE_ARN" | sed 's/role\//role\/x/')

      cat <<EOF > aws-auth-new.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $MODIFIED_ROLE_ARN
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: arn:aws:iam::111122223333:user/new-admin-user
      username: admin-user
      groups:
        - system:masters
EOF

      kubectl apply -f aws-auth-new.yaml
      rm aws-auth-new.yaml

      echo "New aws-auth ConfigMap created and applied successfully with modified role ARN."

      if [ -n "$INSTANCE_ID" ]; then
        echo "Rebooting instance $INSTANCE_ID..."
        sleep 15

        attempts=0
        max_attempts=3
        node_not_ready=false

        while [ $attempts -lt $max_attempts ]; do
          aws ec2 reboot-instances --instance-ids $INSTANCE_ID
          echo "Reboot command sent for instance $INSTANCE_ID (Attempt $((attempts+1)))"
          
          # Wait and check for NotReady state
          for i in {1..20}; do
              node_status=$(kubectl get nodes $NODE_NAME --no-headers | awk '{print $2}')
              if [ "$node_status" = "NotReady" ]; then
                  echo "Node $NODE_NAME successfully transitioned to NotReady state"
                  node_not_ready=true
                  break
              fi
              echo "Node still Ready, waiting 1 second... (Check $i/20)"
              sleep 1
          done  
          
          if [ "$node_not_ready" = true ]; then
            break
          fi
          
          attempts=$((attempts+1))
          if [ $attempts -lt $max_attempts ]; then
            echo "Node did not transition to NotReady state, attempting reboot again..."
          fi
        done

        if [ "$node_not_ready" = false ]; then
          echo "WARNING: Node never transitioned to NotReady state after $max_attempts attempts"
          exit 1
        fi

        echo "Finding and force deleting aws-node pod for the rebooted node..."
        AWS_NODE_POD=$(kubectl get pods -n kube-system -l k8s-app=aws-node --field-selector spec.nodeName=$NODE_NAME -o jsonpath='{.items[0].metadata.name}')
        if [ -n "$AWS_NODE_POD" ]; then
          echo "Found aws-node pod: $AWS_NODE_POD. Force deleting..."
          kubectl delete pod $AWS_NODE_POD -n kube-system --grace-period=0 --force
          echo "aws-node pod force deleted. A new pod will be automatically created."
        else
          echo "No aws-node pod found for node $NODE_NAME"
        fi
        else
        echo "No instance ID found for the node $NODE_NAME"
        fi
    EOT
  }
}

# Latest Working
# resource "null_resource" "modify_aws_auth_and_reboot" {
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = <<-EOT
#       echo "Waiting for a new node to appear..."
#       while true; do
#         NODE_INFO=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{range .items[*]}{.metadata.name} {.spec.providerID}{"\n"}{end}' | head -n 1)
#         if [ -n "$NODE_INFO" ]; then
#           NODE_NAME=$(echo $NODE_INFO | cut -d' ' -f1)
#           INSTANCE_ID=$(echo $NODE_INFO | cut -d' ' -f2 | cut -d'/' -f5)
#           echo "Found a new node: $NODE_NAME with Instance ID: $INSTANCE_ID"
#           break
#         fi
#         echo "No new nodes found yet. Waiting 5 seconds..."
#         sleep 5
#       done

#       echo "Adding taint to prevent non-DaemonSet pods from being scheduled..."
#       kubectl taint nodes $NODE_NAME dedicated=experimental:NoSchedule

#       echo "Waiting for the node to be in Ready state..."
#       while true; do
#         if kubectl get nodes $NODE_NAME -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
#           echo "Node $NODE_NAME is now Ready"
#           break
#         fi
#         echo "Node not Ready yet. Waiting 5 seconds..."
#         sleep 5
#       done

#       echo "Modifying aws-auth ConfigMap..."
#       kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml

#       # Modify the role ARN and add the new user
#       yq eval '.data.mapRoles |= sub("rolearn: ${replace(aws_iam_role.new_nodegroup_3.arn, "/", "\\/")}", "rolearn: ${replace(replace(aws_iam_role.new_nodegroup_3.arn, "role/", "role/x"), "/", "/")}")' -i aws-auth-temp.yaml
#       yq eval '.data.mapUsers += "- groups:\n  - system:masters\n  userarn: arn:aws:iam::111122223333:user/new-admin-user\n  username: admin-user\n"' -i aws-auth-temp.yaml

#       kubectl apply -f aws-auth-temp.yaml
#       rm aws-auth-temp.yaml

#       echo "aws-auth ConfigMap updated successfully."

#       if [ -n "$INSTANCE_ID" ]; then
#         echo "Rebooting instance $INSTANCE_ID..."
#         sleep 25
#         aws ec2 reboot-instances --instance-ids $INSTANCE_ID
#         echo "Reboot command sent for instance $INSTANCE_ID"
#         sleep 8

#         echo "Finding and force deleting aws-node pod for the rebooted node..."
#         AWS_NODE_POD=$(kubectl get pods -n kube-system -l k8s-app=aws-node --field-selector spec.nodeName=$NODE_NAME -o jsonpath='{.items[0].metadata.name}')
#         if [ -n "$AWS_NODE_POD" ]; then
#           echo "Found aws-node pod: $AWS_NODE_POD. Force deleting..."
#           kubectl delete pod $AWS_NODE_POD -n kube-system --grace-period=0 --force
#           echo "aws-node pod force deleted. A new pod will be automatically created."
#         else
#           echo "No aws-node pod found for node $NODE_NAME"
#         fi
#       else
#         echo "No instance ID found for the node $NODE_NAME"
#       fi
#     EOT
#   }
# }




# ###THIS IS A WORKING ONE - JUST W/OUT SAMPLE USER ADDED TO CONFIGMAP

# resource "null_resource" "modify_aws_auth_and_reboot" {
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = <<-EOT
#       echo "Waiting for a new node to appear..."
#       while true; do
#         NODE_INFO=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{range .items[*]}{.metadata.name} {.spec.providerID}{"\n"}{end}' | head -n 1)
#         if [ -n "$NODE_INFO" ]; then
#           NODE_NAME=$(echo $NODE_INFO | cut -d' ' -f1)
#           INSTANCE_ID=$(echo $NODE_INFO | cut -d' ' -f2 | cut -d'/' -f5)
#           echo "Found a new node: $NODE_NAME with Instance ID: $INSTANCE_ID"
#           break
#         fi
#         echo "No new nodes found yet. Waiting 5 seconds..."
#         sleep 5
#       done

#       echo "Adding taint to prevent non-DaemonSet pods from being scheduled..."
#       ##this is to ensure pods do not cause deployment/cleanup issues
#       kubectl taint nodes $NODE_NAME dedicated=experimental:NoSchedule

#       echo "Waiting for the node to be in Ready state..."
#       while true; do
#         if kubectl get nodes $NODE_NAME -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
#           echo "Node $NODE_NAME is now Ready"
#           break
#         fi
#         echo "Node not Ready yet. Waiting 5 seconds..."
#         sleep 5
#       done

#       echo "Modifying aws-auth ConfigMap..."
#       # Get the current aws-auth ConfigMap
#       kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml

#       # Use sed to modify the specific role mapping
#       # The role ARN is escaped to handle special characters
#       sed -i 's|rolearn: ${replace(aws_iam_role.new_nodegroup_3.arn, "/", "\\/")}|rolearn: ${replace(replace(aws_iam_role.new_nodegroup_3.arn, "role/", "role/x"), "/", "\\/")}|' aws-auth-temp.yaml

#       # adding random users
#   #     sed -i '/mapRoles/a\
#   # mapUsers: |\
#   #   - groups:\
#   #     - system:masters\
#   #     userarn: arn:aws:iam::111122223333:user/admin\
#   #     username: admin\
#   #   - groups:\
#   #     - eks-console-dashboard-restricted-access-group\
#   #     userarn: arn:aws:iam::444455556666:user/my-user\
#   #     username: my-user' aws-auth-temp.yaml

#       # Apply the modified ConfigMap
#       kubectl apply -f aws-auth-temp.yaml

#       # Clean up the temporary file
#       rm aws-auth-temp.yaml

#       echo "aws-auth ConfigMap updated successfully."

#       if [ -n "$INSTANCE_ID" ]; then
#         echo "Rebooting instance $INSTANCE_ID..."
#         sleep 10
#         aws ec2 reboot-instances --instance-ids $INSTANCE_ID
#         echo "Reboot command sent for instance $INSTANCE_ID"
#       else
#         echo "No instance ID found for the node $NODE_NAME"
#       fi
#     EOT

#     environment = {
#       KUBECONFIG         = "/home/ec2-user/.kube/config"
#       AWS_DEFAULT_REGION = "us-west-2" # Replace with your AWS region
#     }
#   }

#   depends_on = [null_resource.increase_desired_count, aws_eks_node_group.new_nodegroup_3]
# }



###modifying default nodegroup size to 0 during creation and nodegroup size back to default during destory. 


# resource "null_resource" "ensure_node_group_size" {
#   triggers = {
#     cluster_name    = data.aws_eks_cluster.cluster.id
#     node_group_name = "default"
#     current_min     = data.aws_eks_node_group.default.scaling_config[0].min_size
#     current_max     = data.aws_eks_node_group.default.scaling_config[0].max_size
#     current_desired = data.aws_eks_node_group.default.scaling_config[0].desired_size
#   }

# # This provisioner runs during create and update
# provisioner "local-exec" {
#   command = <<-EOT
#   if [ "${self.triggers.current_min}" -ne 0 ] || [ "${self.triggers.current_desired}" -ne 0 ]; then
#     aws eks update-nodegroup-config \
#       --cluster-name ${self.triggers.cluster_name} \
#       --nodegroup-name ${self.triggers.node_group_name} \
#       --scaling-config minSize=0,maxSize=${self.triggers.current_max},desiredSize=0
#   fi
# EOT
# }

# This provisioner runs during destroy
#   provisioner "local-exec" {
#     when    = destroy
#     command = <<-EOT
#       CURRENT_CONFIG=$(aws eks describe-nodegroup \
#         --cluster-name ${self.triggers.cluster_name} \
#         --nodegroup-name ${self.triggers.node_group_name} \
#         --query 'nodegroup.scalingConfig.[minSize,maxSize,desiredSize]' \
#         --output text)

#       MIN_SIZE=$(echo $CURRENT_CONFIG | awk '{print $1}')
#       MAX_SIZE=$(echo $CURRENT_CONFIG | awk '{print $2}')
#       DESIRED_SIZE=$(echo $CURRENT_CONFIG | awk '{print $3}')

#       if [ "$MIN_SIZE" -ne 3 ] || [ "$MAX_SIZE" -ne 6 ] || [ "$DESIRED_SIZE" -ne 3 ]; then
#         aws eks update-nodegroup-config \
#           --cluster-name ${self.triggers.cluster_name} \
#           --nodegroup-name ${self.triggers.node_group_name} \
#           --scaling-config minSize=3,maxSize=6,desiredSize=3
#       fi
#     EOT
#   }
# }
