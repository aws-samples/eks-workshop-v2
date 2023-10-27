#!/bin/bash

set -a

echo "Cleaning up..."

RSHELL_IDE=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --query 'StackSummaries[].StackName' --output yaml | awk -F - '/rshell/ {print $5}')
aws cloud9 delete-environment --environment-id $RSHELL_IDE

aws iam remove-role-from-instance-profile --role-name AWSCloud9SSMAccessRole --instance-profile-name AWSCloud9SSMInstanceProfile
aws iam delete-instance-profile --instance-profile-name AWSCloud9SSMInstanceProfile
aws iam detach-role-policy --role-name AWSCloud9SSMAccessRole --policy-arn arn:aws:iam::aws:policy/AWSCloud9SSMInstanceProfile
aws iam delete-role --role-name AWSCloud9SSMAccessRole

