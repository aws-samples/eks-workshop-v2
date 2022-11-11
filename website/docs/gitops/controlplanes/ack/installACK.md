---
title: "Configuring ACK Resources"
sidebar_position: 2
---

Installing a controller consists of three steps:
1. Setup of IAM Role Service Account (IRSA) for the controller. It gives the controller the access rights to the AWS resources it controls.
2. Setup the controller K8S resources via Helm
3. Update the Service Account (SA) annotation to have the IRSA working and restart the controller (to simplify)

>The values `$(AWS_ACCOUNT_ID)` and `$(OIDC_PROVIDER)` will be substituted from environment variables.

The first controller to setup is the IAM one which is going to be used for the step 1 for the other controllers.

## IAM controller setup
Create the IAM role with the trust relationship with the Service Account for the IAM Controller.
This role will be use to create the other ACK controller roles. 


View the IAM trust policy running `cat /workspace/modules/ack/iam/trust.json`

Create the `ack-iam-controller` IAM Role using the role policy document `trust.json` and attach the `ack-iam-recommended-policy` recommended policy
```bash hook=ack-install
$ aws iam create-role --role-name "ack-iam-controller" --assume-role-policy-document "$(envsubst </workspace/modules/ack/iam/trust.json)"
$ aws iam put-role-policy \
        --role-name "ack-iam-controller" \
        --policy-name "ack-iam-recommended-policy" \
        --policy-document "file:////workspace/modules/ack/iam/inline-policy.json"
```

Login into public ECR using `helm login`
```bash
$ helm registry login --username AWS --password "$(aws ecr-public get-login-password --region us-east-1)" public.ecr.aws
Login Succeeded
```

Deploy the IAM Controller
```bash
$ helm install --create-namespace -n ack-system ack-iam-controller \
  oci://public.ecr.aws/aws-controllers-k8s/iam-chart --version=v0.0.21 --set=aws.region=$AWS_DEFAULT_REGION --wait
...
STATUS: deployed
...
You are now able to create AWS Identity & Access Management (IAM) resources!
...
```

Annotate Service Account with the IAM role we created
```bash
$ kubectl annotate serviceaccount -n ack-system ack-iam-controller "eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-iam-controller"
serviceaccount/ack-iam-controller annotated
```
Restart the controller to to pick up the new permissions
```bash
$ kubectl -n ack-system rollout restart deployment ack-iam-controller-iam-chart
deployment.apps/ack-iam-controller-iam-chart restarted
```

## EC2 controller setup
Create the IAM role with the trust relationship with the Service Account for the EC2 Controller. This time we use the IAM controller itself to create the role.

View the EC2 Role manifest by running `cat /workspace/modules/ack/ec2/ec2-iam-role.yaml`

```file
ack/ec2/ec2-iam-role.yaml
```

Create the EC2 Role.
```bash
$ kubectl apply -k /workspace/modules/ack/ec2
role.iam.services.k8s.aws/ack-ec2-controller created
```

Wait for Role to be be reconciled
```bash
$ kubectl wait role.iam.services.k8s.aws ack-ec2-controller -n ack-system --for=condition=ACK.ResourceSynced --timeout=2m
```

Deploy the EC2 Controller.
```bash
$ helm install --create-namespace -n ack-system ack-ec2-controller \
  oci://public.ecr.aws/aws-controllers-k8s/ec2-chart --version=v0.0.21 --set=aws.region=$AWS_DEFAULT_REGION --wait
...
STATUS: deployed
...
You are now able to create Amazon Elastic Cloud Compute (EC2) resources!
...
```
Annotate Service Account with the IAM role we created
```bash
$ kubectl annotate serviceaccount -n ack-system ack-ec2-controller "eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-ec2-controller"
serviceaccount/ack-ec2-controller annotated
```
Restart the controller to to pick up the new permissions
```bash
$ kubectl -n ack-system rollout restart deployment ack-ec2-controller-ec2-chart
deployment.apps/ack-ec2-controller-ec2-chart restarted
```

## RDS controller setup
Create the IAM role with the trust relationship with the Service Account for the RDS Controller. This time we use the IAM controller itself to create the role.

View the RDS Role manifest by running `cat /workspace/modules/ack/rds/roles/rds-iam-role.yaml`
```file
ack/rds/roles/rds-iam-role.yaml
```
Create the RDS Role.
```bash
$ kubectl apply -k /workspace/modules/ack/rds/roles
role.iam.services.k8s.aws/ack-rds-controller created
```

Wait for Role to be be reconciled
```bash
$ kubectl wait role.iam.services.k8s.aws ack-rds-controller -n ack-system --for=condition=ACK.ResourceSynced --timeout=2m
```

Create the RDS Controller.
```bash
$ helm install --create-namespace -n ack-system ack-rds-controller \
  oci://public.ecr.aws/aws-controllers-k8s/rds-chart --version=v0.1.1 --set=aws.region=$AWS_DEFAULT_REGION --wait
...
STATUS: deployed
...
You are now able to create Amazon Relational Database Service (RDS) resources!
...
```
Annotate Service Account with the IAM role we created
```bash
$ kubectl annotate serviceaccount -n ack-system ack-rds-controller "eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-rds-controller"
serviceaccount/ack-rds-controller annotated
```
Restart the controller to to pick up the new permissions
```bash
$ kubectl -n ack-system rollout restart deployment ack-rds-controller-rds-chart
deployment.apps/ack-rds-controller-rds-chart restarted
```

## MQ controller setup
Create the IAM role with the trust relationship with the Service Account for the MQ Controller. This time we use the IAM controller itself to create the role.

View the MQ Role manifest by running `cat /workspace/modules/ack/mq/roles/mq-iam-role.yaml`
```file
ack/mq/roles/mq-iam-role.yaml
```

Create the MQ Role.
```bash
$ kubectl apply -k /workspace/modules/ack/mq/roles
role.iam.services.k8s.aws/ack-mq-controller created
```

Wait for Policy and Role to be be reconciled
```bash
$ kubectl wait role.iam.services.k8s.aws ack-mq-controller -n ack-system --for=condition=ACK.ResourceSynced --timeout=2m
```

Deploy the MQ Controller.
```bash
$ helm install --create-namespace -n ack-system ack-mq-controller \
  oci://public.ecr.aws/aws-controllers-k8s/mq-chart --version=v0.0.22 --set=aws.region=$AWS_DEFAULT_REGION --wait
...
STATUS: deployed
...
You are now able to create Amazon MQ (MQ) resources!
...
```
```bash
$ kubectl annotate serviceaccount -n ack-system ack-mq-controller "eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-mq-controller"
serviceaccount/ack-mq-controller annotated
```
```bash
$ kubectl -n ack-system rollout restart deployment ack-mq-controller-mq-chart
deployment.apps/ack-mq-controller-mq-chart restarted
```