#!/bin/bash

# Clean up any resources created by the user OUTSIDE of Terraform here

# All stdout output will be hidden from the user
# To display a message to the user:
# logmessage "Deleting some resource...."


#!/bin/bash

INSTANCE_ID=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{.items[*].spec.providerID}' 2>/dev/null | cut -d '/' -f5 | cut -d ' ' -f1 | head -n1)

if [ -z "$INSTANCE_ID" ]; then
    logmessage "Ignore this message if this is your first time preparing the environment for this section. No instances found in nodegroup new_nodegroup_3. Please be sure to update aws-auth configmap and remove role for new_nodegroup_3 if you have not already."
else
    logmessage "Found instance ID: $INSTANCE_ID"

    INSTANCE_PROFILE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text 2>/dev/null | awk -F'/' '{print $NF}')

    if [ -z "$INSTANCE_PROFILE_NAME" ]; then
        logmessage "Error: Could not find IAM instance profile name for instance $INSTANCE_ID"
    else
        logmessage "Found instance profile name: $INSTANCE_PROFILE_NAME"

        ROLE_ARN=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --query 'InstanceProfile.Roles[0].Arn' --output text 2>/dev/null)

        if [ -z "$ROLE_ARN" ]; then
            logmessage "Error: Could not find role ARN for instance profile $INSTANCE_PROFILE_NAME"
        else
            logmessage "Found role ARN: $ROLE_ARN"
            logmessage "Checking current configmap"
            logmessage "$(kubectl describe configmap aws-auth -n kube-system)"
            logmessage "Modifying aws-auth ConfigMap..."
            if kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml; then
                # Create a temporary file with the role ARN
                echo "$ROLE_ARN" > role_arn.txt
                
                # Remove 'x' only from new_nodegroup_3 role ARN and remove duplicate entries
                yq eval '
                    .data.mapRoles = (.data.mapRoles | sub("rolearn: arn:aws:iam::[0-9]+:role/xnew_nodegroup_3", "rolearn: " + load("role_arn.txt"))) |
                    .data.mapRoles = (.data.mapRoles | split("\n") | unique | join("\n")) |
                    del(.data.mapUsers)
                ' -i aws-auth-temp.yaml

                # Clean up temporary file
                rm role_arn.txt

                logmessage "Debugging: Showing contents of modified aws-auth ConfigMap"
                logmessage "$(cat aws-auth-temp.yaml)"

                logmessage "Applying modified ConfigMap..."
                if kubectl apply -f aws-auth-temp.yaml; then
                    logmessage "aws-auth ConfigMap updated successfully."
                    logmessage "Final output using kubectl"
                    logmessage "$(kubectl describe cm -n kube-system aws-auth)"
                else
                    logmessage "Error: Failed to apply modified aws-auth ConfigMap."
                fi

                rm aws-auth-temp.yaml
            else
                logmessage "Error: Failed to retrieve aws-auth ConfigMap."
            fi
        fi
    fi
fi



# ##latest working
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
#             logmessage "Checking current configmap"
#             logmessage "$(kubectl describe configmap aws-auth -n kube-system)"
#             logmessage "Modifying aws-auth ConfigMap..."
#             if kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-temp.yaml; then
#                 # Get the actual role ARN
#                 INSTANCE_ID=$(kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_3 -o jsonpath='{.items[*].spec.providerID}' | cut -d '/' -f5 | cut -d ' ' -f1 | head -n1)
#                 INSTANCE_PROFILE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' --output text | awk -F'/' '{print $NF}')
#                 ROLE_ARN=$(aws iam get-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --query 'InstanceProfile.Roles[0].Arn' --output text)

#                 # Remove 'x' only from new_nodegroup_3 role ARN
#                 yq eval --env-var ACTUAL_ROLE_ARN="$ROLE_ARN" '
#                     .data.mapRoles |= sub("rolearn: arn:aws:iam::[0-9]+:role/xnew_nodegroup_3", "rolearn: " + strenv(ACTUAL_ROLE_ARN)) |
#                     del(.data.mapUsers)
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

