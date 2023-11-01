#!/bin/bash

set -a

echo "Creating SSM Instance profile for Cloud9"
SSMROLE=$(aws iam create-role --role-name AWSCloud9SSMAccessRole --path /service-role/ --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{"Effect": "Allow","Principal": {"Service": ["ec2.amazonaws.com","cloud9.amazonaws.com"]},"Action": "sts:AssumeRole"}]}' --query 'Role.Name' --output text)
aws iam attach-role-policy --role-name AWSCloud9SSMAccessRole --policy-arn arn:aws:iam::aws:policy/AWSCloud9SSMInstanceProfile
SSMINSTANCEPROFILE=$(aws iam create-instance-profile --instance-profile-name AWSCloud9SSMInstanceProfile --path /cloud9/ --query 'InstanceProfile.Name' --output text)
aws iam add-role-to-instance-profile --instance-profile-name AWSCloud9SSMInstanceProfile --role-name AWSCloud9SSMAccessRole
echo "---"

echo "Exporting vars to create the new Cloud9 environment on the same subnet as the EKS Cluster."
RSHELL_SUBNET=$(aws ec2 describe-subnets --query 'Subnets[0].SubnetId' --filters "Name=tag:Name,Values=*SubnetPrivate*" --output text)
echo "---"

echo "Creating Cloud9 environment"
RSHELL_IDE=$(aws cloud9 create-environment-ec2 --name rshell --instance-type t2.micro --connection-type CONNECT_SSM --subnet-id $RSHELL_SUBNET --query 'environmentId' --output text)
sleep 60
echo "---"

echo "Openning port 6666 to allow the reverse shell simulation"
RSHELL_SG=$(aws cloudformation describe-stack-resource --stack-name aws-cloud9-rshell-$RSHELL_IDE --logical-resource-id InstanceSecurityGroup --query 'StackResourceDetail.PhysicalResourceId' --output text)
SG_INGRESS=$(aws ec2 authorize-security-group-ingress --group-id $RSHELL_SG --protocol all --port 6660-6669 --cidr 10.42.0.0/16 --query 'SecurityGroupRules[].SecurityGroupRuleId' --output text)
echo "---"

# Exposing the new Cloud9 Environment console URL.
echo "https://$AWS_REGION.console.aws.amazon.com/cloud9/ide/$RSHELL_IDE"