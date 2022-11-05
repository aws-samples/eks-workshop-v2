---
title: "Configuring ACK Resources"
sidebar_position: 2
---

Installing a controller consists of three steps:
1. Setup of Iam Role Service Account (IRSA) for the controller. It gives the controller the access rights to the AWS resources it controls.
2. Setup the controller K8S resources via Helm
3. Update the SA annotation to have the IRSA working and restart the controller (to simplify)

>The values `$(AWS_ACCOUNT_ID)` and `$(OIDC_PROVIDER)` will be substituted from environment variables.

The first controller to setup is the IAM one which is going to be used for the step 1 for the other controllers.

## IAM controller setup
Create the IAM role with the trust relationship with the Service Account for the IAM Controller.
This role will be use to create the other ACK controller roles. 

```bash
$ cat <<EOF > trust.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:ack-system:ack-iam-controller"
        }
      }
    }
  ]
}
EOF

$ aws iam create-role --role-name "ack-iam-controller" --assume-role-policy-document file://trust.json 

$ aws iam put-role-policy \
        --role-name "ack-iam-controller" \
        --policy-name "ack-iam-recommended-policy" \
        --policy-document "$(curl -s https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/main/config/iam/recommended-inline-policy)"
```

Deploy the IAM Controller
```bash
$ aws ecr-public get-login-password --region ${AWS_DEFAULT_REGION} | helm registry login --username AWS --password-stdin public.ecr.aws

$ helm install --create-namespace -n ack-system ack-iam-controller \
  oci://public.ecr.aws/aws-controllers-k8s/iam-chart --version=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/iam-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4) --set=aws.region=$AWS_DEFAULT_REGION

$ kubectl annotate serviceaccount -n ack-system ack-iam-controller "eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-iam-controller"

$ kubectl -n ack-system rollout restart deployment ack-iam-controller-iam-chart
```

## EC2 controller setup
Create the IAM role with the trust relationship with the Service Account for the EC2 Controller. This time we use the IAM controller itself to create the role.

Create the EC2 Role manifest

```file
ack/ec2/ec2-iam-role.yaml
```

Create the EC2 Role.
```bash
$ kubectl apply -k /workspace/modules/ack/ec2
```

Deploy the EC2 Controller.
```bash
$ helm install --create-namespace -n ack-system ack-ec2-controller \
  oci://public.ecr.aws/aws-controllers-k8s/ec2-chart --version=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/ec2-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4) --set=aws.region=$AWS_DEFAULT_REGION

$ kubectl annotate serviceaccount -n ack-system ack-ec2-controller "eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-ec2-controller"

$ kubectl -n ack-system rollout restart deployment ack-ec2-controller-ec2-chart
```

## RDS controller setup
Create the IAM role with the trust relationship with the Service Account for the RDS Controller. This time we use the IAM controller itself to create the role.

Create the RDS Role manifest
```file
ack/rds/rds-iam-role.yaml
```
Create the RDS Role.
```bash
$ kubectl apply -k /workspace/modules/ack/rds
```

Create the RDS Controller.
```bash
$ helm install --create-namespace -n ack-system ack-rds-controller \
  oci://public.ecr.aws/aws-controllers-k8s/rds-chart --version=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/rds-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4) --set=aws.region=$AWS_DEFAULT_REGION

$ kubectl annotate serviceaccount -n ack-system ack-rds-controller "eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-rds-controller"

$ kubectl -n ack-system rollout restart deployment ack-rds-controller-rds-chart
```

## MQ controller setup
Create the IAM role with the trust relationship with the Service Account for the MQ Controller. This time we use the IAM controller itself to create the role.

Create the RDS Role manifest
```file
ack/mq/mq-iam-role.yaml
```
Create the RDS Role.
```bash
$ kubectl apply -k /workspace/modules/ack/mq
```

Create the MQ Controller.
```bash
$ helm install --create-namespace -n ack-system ack-mq-controller \
  oci://public.ecr.aws/aws-controllers-k8s/mq-chart --version=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/mq-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4) --set=aws.region=$AWS_DEFAULT_REGION

$ kubectl annotate serviceaccount -n ack-system ack-mq-controller "eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-mq-controller"

$ kubectl -n ack-system rollout restart deployment ack-mq-controller-mq-chart
```