#!/bin/bash

# Clean up any resources created by the user OUTSIDE of Terraform here

# All stdout output will be hidden from the user
# To display a message to the user:
# logmessage "Deleting some resource...."

#!/bin/bash

# Add error handling
set -e

INSTANCE_ID=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{.items[*].spec.providerID}' 2>/dev/null | cut -d '/' -f5 | cut -d ' ' -f1 | head -n1)

if [ -z "$INSTANCE_ID" ]; then
    logmessage "Ignore this message if this is your first time preparing the environment for this section. No instances found in nodegroup new_nodegroup_3. Please be sure to update aws-auth configmap and remove role for new_nodegroup_3 if you have not already."
    exit 0
fi

logmessage "Found instance ID: $INSTANCE_ID"

INSTANCE_PROFILE_NAME=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text 2>/dev/null | awk -F'/' '{print $NF}')

if [ -z "$INSTANCE_PROFILE_NAME" ]; then
    logmessage "Error: Could not find IAM instance profile name for instance $INSTANCE_ID"
    exit 1
fi

logmessage "Found instance profile name: $INSTANCE_PROFILE_NAME"

ROLE_NAME=$(aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --query 'InstanceProfile.Roles[0].RoleName' --output text 2>/dev/null)

if [ -z "$ROLE_NAME" ]; then
    logmessage "Error: Could not find role name for instance profile $INSTANCE_PROFILE_NAME"
    exit 1
fi

logmessage "Found role name: $ROLE_NAME"

# Get the full role ARN
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)

if [ -z "$ROLE_ARN" ]; then
    logmessage "Error: Could not get role ARN for role $ROLE_NAME"
    exit 1
fi

# Create a fresh aws-auth ConfigMap
cat << EOF > aws-auth-temp.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: ${ROLE_ARN}
      username: system:node:{{EC2PrivateDNSName}}
  mapUsers: ""
EOF

logmessage "Debugging: Showing contents of new aws-auth ConfigMap"
logmessage "$(cat aws-auth-temp.yaml)"

logmessage "Applying new ConfigMap..."
if kubectl apply -f aws-auth-temp.yaml; then
    logmessage "aws-auth ConfigMap updated successfully."
else
    logmessage "Error: Failed to apply aws-auth ConfigMap."
    rm -f aws-auth-temp.yaml
    exit 1
fi

rm -f aws-auth-temp.yaml
logmessage "Script execution completed."


#Executes

# #!/bin/bash

# INSTANCE_ID=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{.items[*].spec.providerID}' 2>/dev/null | cut -d '/' -f5 | cut -d ' ' -f1 | head -n1)

# if [ -z "$INSTANCE_ID" ]; then
#     logmessage "Ignore this message if this is your first time preparing the environment for this section. No instances found in nodegroup new_nodegroup_3. Please be sure to update aws-auth configmap and remove role for new_nodegroup_3 if you have not already."
# else
#     logmessage "Found instance ID: $INSTANCE_ID"

#     INSTANCE_PROFILE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text 2>/dev/null | awk -F'/' '{print $NF}')

#     if [ -z "$INSTANCE_PROFILE_NAME" ]; then
#         logmessage "Error: Could not find IAM instance profile name for instance $INSTANCE_ID"
#     else
#         logmessage "Found instance profile name: $INSTANCE_PROFILE_NAME"

#         ROLE_NAME=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --query 'InstanceProfile.Roles[0].RoleName' --output text 2>/dev/null)

#         if [ -z "$ROLE_NAME" ]; then
#             logmessage "Error: Could not find role name for instance profile $INSTANCE_PROFILE_NAME"
#         else
#             logmessage "Found role name: $ROLE_NAME"

#             logmessage "Modifying aws-auth ConfigMap..."
#             logmessage "Checking current configmap"
#             logmessage "$(kubectl describe configmap aws-auth -n kube-system)"
#             if kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml; then
#                 # First modify the ConfigMap
#                 yq eval '
#                     .data.mapRoles |= (
#                         split("\n") | 
#                         map(select(. != "")) | 
#                         map(sub("role/x" + strenv(ROLE_NAME), "role/" + strenv(ROLE_NAME))) |
#                         join("\n")
#                     ) |
#                     .data.mapUsers = ""
#                 ' -i aws-auth-temp.yaml

#                 # Then remove duplicate entries
#                 yq eval '
#                     .data.mapRoles |= (
#                         split("\n") | 
#                         map(select(. != "")) | 
#                         unique | 
#                         join("\n")
#                     )
#                 ' -i aws-auth-temp.yaml

#                 logmessage "Debugging: Showing contents of modified aws-auth ConfigMap"
#                 logmessage "$(cat aws-auth-temp.yaml)"

#                 logmessage "Applying modified ConfigMap..."
#                 if kubectl apply -f aws-auth-temp.yaml; then
#                     logmessage "aws-auth ConfigMap updated successfully."
#                 else
#                     logmessage "Error: Failed to apply modified aws-auth ConfigMap."
#                 fi

#                 rm aws-auth-temp.yaml
#             else
#                 logmessage "Error: Failed to retrieve aws-auth ConfigMap."
#             fi
#         fi
#     fi
# fi

# logmessage "Script execution completed."

# #Executes, just didn't do the job well
# #!/bin/bash 

# INSTANCE_ID=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{.items[*].spec.providerID}' 2>/dev/null | cut -d '/' -f5 | cut -d ' ' -f1 | head -n1)

# if [ -z "$INSTANCE_ID" ]; then
#     logmessage "Ignore this message if this is your first time preparing the environment for this section. No instances found in nodegroup new_nodegroup_3. Please be sure to update aws-auth configmap and remove role for new_nodegroup_3 if you have not already."
# else
#     logmessage "Found instance ID: $INSTANCE_ID"

#     INSTANCE_PROFILE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text 2>/dev/null | awk -F'/' '{print $NF}')

#     if [ -z "$INSTANCE_PROFILE_NAME" ]; then
#         logmessage "Error: Could not find IAM instance profile name for instance $INSTANCE_ID"
#     else
#         logmessage "Found instance profile name: $INSTANCE_PROFILE_NAME"

#         ROLE_NAME=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --query 'InstanceProfile.Roles[0].RoleName' --output text 2>/dev/null)

#         if [ -z "$ROLE_NAME" ]; then
#             logmessage "Error: Could not find role name for instance profile $INSTANCE_PROFILE_NAME"
#         else
#             logmessage "Found role name: $ROLE_NAME"

#             logmessage "Modifying aws-auth ConfigMap..."
#             logmessage "Checking current configmap"
#             logmessage "$(kubectl describe configmap aws-auth -n kube-system)"
#             if kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml; then
#                 # First Remove 'x' from role name and clear mapUsers
#                 yq eval '
#                     .data.mapRoles |= capture("(?P<prefix>rolearn: arn:aws:iam::)(?P<account>[0-9]+)(?P<suffix>:role/x)" + strenv(ROLE_NAME)) as $captured |
#                     if $captured then
#                         .data.mapRoles |= sub("rolearn: arn:aws:iam::[0-9]+:role/x" + strenv(ROLE_NAME), $captured.prefix + $captured.account + ":role/" + strenv(ROLE_NAME))
#                     else . end |
#                     .data.mapUsers = ""
#                 ' -i aws-auth-temp.yaml

#                 # Then remove duplicate entries from mapRoles
#                 logmessage "Checking for and removing duplicate role entries..."
#                 yq eval '
#                     .data.mapRoles = (
#                         .data.mapRoles | 
#                         split("\n") | 
#                         map(select(. != "")) | 
#                         group_by(.) | 
#                         map(.[0]) | 
#                         join("\n")
#                     )
#                 ' -i aws-auth-temp.yaml

#                 logmessage "Debugging: Showing contents of modified aws-auth ConfigMap"
#                 logmessage "$(cat aws-auth-temp.yaml)"

#                 logmessage "Applying modified ConfigMap..."
#                 if kubectl apply -f aws-auth-temp.yaml; then
#                     logmessage "aws-auth ConfigMap updated successfully."
#                 else
#                     logmessage "Error: Failed to apply modified aws-auth ConfigMap."
#                 fi

#                 rm aws-auth-temp.yaml
#             else
#                 logmessage "Error: Failed to retrieve aws-auth ConfigMap."
#             fi
#         fi
#     fi
# fi

# logmessage "Script execution completed."


# #!/bin/bash

# INSTANCE_ID=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{.items[*].spec.providerID}' 2>/dev/null | cut -d '/' -f5 | cut -d ' ' -f1 | head -n1)

# if [ -z "$INSTANCE_ID" ]; then
#     logmessage "Ignore this message if this is your first time preparing the environment for this section. No instances found in nodegroup new_nodegroup_3. Please be sure to update aws-auth configmap and remove role for new_nodegroup_3 if you have not already."
# else
#     logmessage "Found instance ID: $INSTANCE_ID"

#     INSTANCE_PROFILE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text 2>/dev/null | awk -F'/' '{print $NF}')

#     if [ -z "$INSTANCE_PROFILE_NAME" ]; then
#         logmessage "Error: Could not find IAM instance profile name for instance $INSTANCE_ID"
#     else
#         logmessage "Found instance profile name: $INSTANCE_PROFILE_NAME"

#         ROLE_NAME=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --query 'InstanceProfile.Roles[0].RoleName' --output text 2>/dev/null)

#         if [ -z "$ROLE_NAME" ]; then
#             logmessage "Error: Could not find role name for instance profile $INSTANCE_PROFILE_NAME"
#         else
#             logmessage "Found role name: $ROLE_NAME"

#             logmessage "Modifying aws-auth ConfigMap..."
#             if kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml; then
#                 # Remove 'x' from role name and remove the sample user
#                 yq eval '
#                     .data.mapRoles |= sub("rolearn: arn:aws:iam::[0-9]+:role/x" + strenv(ROLE_NAME), "rolearn: arn:aws:iam::[0-9]+:role/" + strenv(ROLE_NAME)) |
#                     .data.mapUsers |= select(. != null) |
#                     (.data.mapUsers | select(. != null)) -= "- groups:\n  - system:masters\n  userarn: arn:aws:iam::111122223333:user/new-admin-user\n  username: admin-user\n"
#                 ' -i aws-auth-temp.yaml

#                 logmessage "Debugging: Showing contents of modified aws-auth ConfigMap"
#                 cat aws-auth-temp.yaml

#                 logmessage "Applying modified ConfigMap..."
#                 if kubectl apply -f aws-auth-temp.yaml; then
#                     logmessage "aws-auth ConfigMap updated successfully."
#                 else
#                     logmessage "Error: Failed to apply modified aws-auth ConfigMap."
#                 fi

#                 rm aws-auth-temp.yaml
#             else
#                 logmessage "Error: Failed to retrieve aws-auth ConfigMap."
#             fi
#         fi
#     fi
# fi

# logmessage "Script execution completed."



# INSTANCE_ID=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{.items[*].spec.providerID}' 2>/dev/null | cut -d '/' -f5 | cut -d ' ' -f1 | head -n1)

# if [ -z "$INSTANCE_ID" ]; then
#     logmessage "Ignore this message if this is your first time preparing the environment for this section. No instances found in nodegroup new_nodegroup_3. Please be sure to update aws-auth configmap and remove role for new_nodegroup_3 if you have not already."
# else
#     logmessage "Found instance ID: $INSTANCE_ID"

#     INSTANCE_PROFILE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text 2>/dev/null | awk -F'/' '{print $NF}')

#     if [ -z "$INSTANCE_PROFILE_NAME" ]; then
#         logmessage "Error: Could not find IAM instance profile name for instance $INSTANCE_ID"
#     else
#         logmessage "Found instance profile name: $INSTANCE_PROFILE_NAME"

#         ROLE_NAME=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --query 'InstanceProfile.Roles[0].RoleName' --output text 2>/dev/null)

#         if [ -z "$ROLE_NAME" ]; then
#             logmessage "Error: Could not find role name for instance profile $INSTANCE_PROFILE_NAME"
#         else
#             logmessage "Found role name: $ROLE_NAME"

#             logmessage "Modifying aws-auth ConfigMap..."
#             if kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml; then
#                 # First Remove 'x' from role name and clear mapUsers
#                 yq eval '
#                     .data.mapRoles |= capture("(?P<prefix>rolearn: arn:aws:iam::)(?P<account>[0-9]+)(?P<suffix>:role/x)" + strenv(ROLE_NAME)) as $captured |
#                     if $captured then
#                         .data.mapRoles |= sub("rolearn: arn:aws:iam::[0-9]+:role/x" + strenv(ROLE_NAME), $captured.prefix + $captured.account + ":role/" + strenv(ROLE_NAME))
#                     else . end |
#                     .data.mapUsers = ""
#                 ' -i aws-auth-temp.yaml

#                 # Then remove duplicate entries from mapRoles
#                 logmessage "Checking for and removing duplicate role entries..."
#                 yq eval '
#                     .data.mapRoles = (
#                         .data.mapRoles | 
#                         split("\n") | 
#                         map(select(. != "")) | 
#                         group_by(.) | 
#                         map(.[0]) | 
#                         join("\n")
#                     )
#                 ' -i aws-auth-temp.yaml

#                 logmessage "Debugging: Showing contents of modified aws-auth ConfigMap"
#                 cat aws-auth-temp.yaml

#                 logmessage "Applying modified ConfigMap..."
#                 if kubectl apply -f aws-auth-temp.yaml; then
#                     logmessage "aws-auth ConfigMap updated successfully."
#                 else
#                     logmessage "Error: Failed to apply modified aws-auth ConfigMap."
#                 fi

#                 rm aws-auth-temp.yaml
#             else
#                 logmessage "Error: Failed to retrieve aws-auth ConfigMap."
#             fi
#         fi
#     fi
# fi

# logmessage "Script execution completed."




# #This works, just doesn't remove x and admin role
#!/bin/bash

# INSTANCE_ID=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{.items[*].spec.providerID}' 2>/dev/null | cut -d '/' -f5 | cut -d ' ' -f1 | head -n1)

# if [ -z "$INSTANCE_ID" ]; then
#     logmessage "Ignore this message if this is your first time preparing the environment for this section. No instances found in nodegroup new_nodegroup_3. Please be sure to update aws-auth configmap and remove role for new_nodegroup_3 if you have not already."
# else
#     logmessage "Found instance ID: $INSTANCE_ID"

#     INSTANCE_PROFILE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text 2>/dev/null | awk -F'/' '{print $NF}')

#     if [ -z "$INSTANCE_PROFILE_NAME" ]; then
#         logmessage "Error: Could not find IAM instance profile name for instance $INSTANCE_ID"
#     else
#         logmessage "Found instance profile name: $INSTANCE_PROFILE_NAME"

#         ROLE_NAME=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --query 'InstanceProfile.Roles[0].RoleName' --output text 2>/dev/null)

#         if [ -z "$ROLE_NAME" ]; then
#             logmessage "Error: Could not find role name for instance profile $INSTANCE_PROFILE_NAME"
#         else
#             logmessage "Found role name: $ROLE_NAME"

#             logmessage "Modifying aws-auth ConfigMap..."
#             if kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml; then
#                 # FRemove 'x' from role name and remove the sample user
#                 yq eval '
#                     .data.mapRoles |= sub("rolearn: arn:aws:iam::[0-9]+:role/x" + strenv(ROLE_NAME), "rolearn: arn:aws:iam::[0-9]+:role/" + strenv(ROLE_NAME)) |
#                     .data.mapUsers |= select(. != null) |
#                     (.data.mapUsers | select(. != null)) -= "- groups:\n  - system:masters\n  userarn: arn:aws:iam::111122223333:user/new-admin-user\n  username: admin-user\n"
#                 ' -i aws-auth-temp.yaml

#                 # Remove duplicate role entries
#                 logmessage "Checking for and removing duplicate role entries..."
#                 yq eval '
#                     .data.mapRoles = (
#                         .data.mapRoles | 
#                         split("\n") | 
#                         map(select(. != "")) | 
#                         group_by(.) | 
#                         map(.[0]) | 
#                         join("\n")
#                     )
#                     ) |
#                             .data.mapUsers = (
#                     .data.mapUsers | 
#                         select(. != null) |
#                         split("\n") | 
#                         map(select(. != "")) | 
#                         group_by(.) | 
#                         map(.[0]) | 
#                         join("\n")
#                 )
#                 ' -i aws-auth-temp.yaml

#                 logmessage "Debugging: Showing contents of modified aws-auth ConfigMap"
#                 cat aws-auth-temp.yaml

#                 logmessage "Applying modified ConfigMap..."
#                 if kubectl apply -f aws-auth-temp.yaml; then
#                     logmessage "aws-auth ConfigMap updated successfully."
#                 else
#                     logmessage "Error: Failed to apply modified aws-auth ConfigMap."
#                 fi

#                 rm aws-auth-temp.yaml
#             else
#                 logmessage "Error: Failed to retrieve aws-auth ConfigMap."
#             fi
#         fi
#     fi
# fi

# logmessage "Script execution completed."