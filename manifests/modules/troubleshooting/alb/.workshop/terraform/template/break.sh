#!/usr/bin/env bash
#. .env

set -e

mkdir -p /eks-workshop/logs
log_file=/eks-workshop/logs/action-$(date +%s).log

exec 2>&1

logmessage() {
  echo "$@" >&7
  echo "$@" >&1
}
export -f logmessage

# Function to get the role name from a role ARN
get_role_name_from_arn() {
    local role_arn=$1

    # Extract the role name from the ARN
    role_name=$(logmessage "$role_arn" | awk -F'/' '{print $NF}')

    if [ -n "$role_name" ]; then
        logmessage "$role_name"
    else
        logmessage "Failed to retrieve role name from ARN: $role_arn"
        return 1
    fi
}

# Function to get the Kubernetes role attached to a service account
get_service_account_role() {
    local namespace=$1
    local service_account=$2

    # Get the role ARN associated with the service account
    role_arn=$(kubectl get serviceaccount "$service_account" -n "$namespace" -o jsonpath="{.metadata.annotations['eks\.amazonaws\.com\/role-arn']}")

    if [ -n "$role_arn" ]; then
        logmessage "Service Account: $service_account"
        logmessage "Namespace: $namespace"
        logmessage "Role ARN: $role_arn"
        get_role_name_from_arn "$role_arn"
        return 0
    else
        logmessage "Failed to retrieve role for service account '$service_account' in namespace '$namespace'"
        return 1
    fi
    
}

# Function to get the first policy ARN attached to a role ARN
get_first_policy_arn_from_role_arn() {
    local role_arn=$1

    # Get the list of policies attached to the role
    policy_arn=$(aws iam list-attached-role-policies --role-name "$role_arn" --query 'AttachedPolicies[0].PolicyArn' --output text)

    if [ -n "$policy_arn" ]; then
        logmessage "First Policy ARN attached to role '$role_arn':"
        logmessage "Policy: $policy_arn"
        return 0
    else
        logmessage "Failed to retrieve policy ARN for role '$role_arn'"
        return 1
    fi    
}

# Function to update the policy with new statement
update_policy_with_new_statement() {
    local policy_arn=$1
    local new_statement=$2
    
    logmessage "PolicyARN: $policy_arn"
    logmessage "Statement: $new_statement"
    aws iam create-policy-version --policy-arn $policy_arn --policy-document $new_statement --set-as-default
    
}

# Function to remove an action from a policy statement
remove_action_from_policy_statement() {
    local policy_name=$1
    local action_to_remove=$2

    # Get the current policy document
    policy_document=$(aws iam get-policy-version --policy-arn "$policy_arn" --query 'PolicyVersion.Document' --version-id v1 --output json)

    # Remove the specified action from the statements
    new_statements=$(logmessage "$policy_document" | jq ".Statement[] | select(.Action[] | contains('$action_to_remove')) | .Action = [.Action[] | select(. != '$action_to_remove')]")
    new_policy_document=$(logmessage '{"Version": "2012-10-17", "Statement": '"$new_statements"'}')
+
    # Update the policy with the modified document
    logmessage "Policy Document"
    logmessage $new_policy_document
    #aws iam create-policy-version --policy-arn "$policy_arn" --policy-document "$new_policy_document" --set-as-default

    if [ $? -eq 0 ]; then
        logmessage "Action removed from policy statement successfully."
        return 0
    else
        logmessage "Failed to remove action from policy statement."
        return 1
    fi
}

# Function to remove tags from subnets ids
remove_tags_from_subnets() {
    local tag_key="Key=kubernetes.io/role/elb,Value=1"

    logmessage "retrive subnets ids with tag key assigned to specific vpc_id via aws cli"    
    logmessage "getting public subnets from VPC: $vpc_id "
    

    subnets_vpc=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].SubnetId' --output text)
    logmessage "subnets_vpc: $subnets_vpc"
    
        
#remove tag from subnets with AWS cli
    for subnet_id in $subnets_vpc; do
        logmessage "public subnets: $subnet_id"
        aws ec2 delete-tags --resources "$subnet_id" --tags "Key=$tag_key" || logmessage "Failed to remove tag from subnet $subnet_id"
    done
    return 0
}

# Getting the service role
path_tofile=$1
mode=$2
vpc_id=$3
public_subnets=$4
namespace="kube-system"
service_account="aws-load-balancer-controller-sa"
#new_statement="file://$path_tofile/template/iam_policy_incorrect.json"
new_statement="file://$path_tofile/template/other_issue.json"

logmessage "path_sent: $path_tofile"


# validate if mode is equal to mod1
logmessage "mode: $mode"
if [ "$mode" == "mod1" ]; then
    logmessage "Removing subnet tags"
    remove_tags_from_subnets
else
    logmessage "Removing permissions"
    get_service_account_role "$namespace" "$service_account"
    get_first_policy_arn_from_role_arn "$role_name"
    update_policy_with_new_statement "$policy_arn" "$new_statement"

fi




