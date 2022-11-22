---
title: "Configuring ACK Resources"
sidebar_position: 2
---
Installing the contollers is usually an activity done by the cluster admins. The application teams are responsible to setup AWS resources via the controllers. They can define the application and its dependencies in one single Helm chart, thanks to the controllers.   

Installing a controller consists of three steps:
1. Setup of IAM Role Service Account (IRSA) for the controller. It gives the controller the access rights to the AWS resources it controls.
2. Setup the controller K8S resources via Helm.
3. Update the Service Account (SA) annotation to have the IRSA working and restart the controller (to simplify).

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
  oci://public.ecr.aws/aws-controllers-k8s/iam-chart --version=v0.0.21 \
  --set=aws.region=$AWS_DEFAULT_REGION \
  --set=serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-iam-controller" --wait
...
STATUS: deployed
...
You are now able to create AWS Identity & Access Management (IAM) resources!
...
```

## EC2 controller setup
Create the IAM role with the trust relationship with the Service Account for the EC2 Controller. This time we use the IAM controller itself to create the role.

View the EC2 Role manifest by running `cat /workspace/modules/ack/ec2/ec2-iam-role.yaml`

```file
ack/ec2/ec2-iam-role.yaml
```

Deploy the EC2 IAM Role and EC2 Controller.
```bash
$ kubectl apply -k /workspace/modules/ack/ec2
role.iam.services.k8s.aws/ack-ec2-controller created

$ kubectl wait role.iam.services.k8s.aws ack-ec2-controller -n ack-system --for=condition=ACK.ResourceSynced --timeout=2m
role.iam.services.k8s.aws/ack-ec2-controller condition met

$ helm install --create-namespace -n ack-system ack-ec2-controller \
  oci://public.ecr.aws/aws-controllers-k8s/ec2-chart --version=v0.1.0 \
  --set=aws.region=$AWS_DEFAULT_REGION \
  --set=serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-ec2-controller" --wait
...
STATUS: deployed
...
You are now able to create Amazon Elastic Cloud Compute (EC2) resources!
...
```

## RDS controller setup
Create the IAM role with the trust relationship with the Service Account for the RDS Controller. This time we use the IAM controller itself to create the role.

View the RDS Role manifest by running `cat /workspace/modules/ack/rds/roles/rds-iam-role.yaml`
```file
ack/rds/roles/rds-iam-role.yaml
```

Deploy RDS Role and RDS Controller
```bash
$ kubectl apply -k /workspace/modules/ack/rds/roles
role.iam.services.k8s.aws/ack-rds-controller created

$ kubectl wait role.iam.services.k8s.aws ack-rds-controller -n ack-system --for=condition=ACK.ResourceSynced --timeout=2m
role.iam.services.k8s.aws/ack-rds-controller condition met

$ helm install --create-namespace -n ack-system ack-rds-controller \
  oci://public.ecr.aws/aws-controllers-k8s/rds-chart --version=v0.1.1 \
  --set=aws.region=$AWS_DEFAULT_REGION \
  --set=serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-rds-controller" --wait
...
STATUS: deployed
...
You are now able to create Amazon Relational Database Service (RDS) resources!
...
```


<!-- TODO: Uncomment once MQ issue in ACK is resolved https://github.com/aws-controllers-k8s/community/issues/1517
## MQ controller setup
Create the IAM role with the trust relationship with the Service Account for the MQ Controller. This time we use the IAM controller itself to create the role.

View the MQ Role manifest by running `cat /workspace/modules/ack/mq/roles/mq-iam-role.yaml`
```file
ack/mq/roles/mq-iam-role.yaml
```

Deploy MQ Role and MQ Controller
```bash
$ kubectl apply -k /workspace/modules/ack/mq/roles
role.iam.services.k8s.aws/ack-mq-controller created

$ kubectl wait role.iam.services.k8s.aws ack-mq-controller -n ack-system --for=condition=ACK.ResourceSynced --timeout=2m
role.iam.services.k8s.aws/ack-mq-controller condition met

$ helm install --create-namespace -n ack-system ack-mq-controller \
  oci://public.ecr.aws/aws-controllers-k8s/mq-chart --version=v0.0.23 \
  --set=aws.region=$AWS_DEFAULT_REGION \
  --set=serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/ack-mq-controller" --wait
...
STATUS: deployed
...
You are now able to create Amazon MQ (MQ) resources!
```
-->