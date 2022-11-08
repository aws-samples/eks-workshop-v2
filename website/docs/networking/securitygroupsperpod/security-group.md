---
title: "Security Group Setup"
sidebar_position: 50
weight: 50
---

### Enable Cloud9 Acccess To RDS

i. First, get the instance id of the Cloud9 instance from the instance metadata service:

```bash
$ export C9_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
```

ii. Locate the existing security group attached to the Cloud9 instance:

```bash
$ export C9_SG=$(aws ec2 describe-instances --output text \
--query 'Reservations[*].Instances[*].NetworkInterfaces[*].Groups[*].GroupId' \
--region ${AWS_DEFAULT_REGION} --instance-ids ${C9_INSTANCE_ID})
```

iii. Add Cloud9 security group to the allowed list on the RDS security group:

```bash
$ aws ec2 authorize-security-group-ingress \
--group-id ${NETWORKING_RDS_SG_ID} \
--protocol tcp \
--port 5432 \
--source-group ${C9_SG}
```

### Create Pod Security Group

i. Now, let’s create the pod security group (POD_SG):

```bash
$ aws ec2 create-security-group \
--description 'POD SG' \
--group-name 'POD_SG' \
--vpc-id ${VPC_ID}
```

ii. Export the pod security group id:

```bash
$ export POD_SG=$(aws ec2 describe-security-groups \
--filters Name=group-name,Values=POD_SG Name=vpc-id,Values=${VPC_ID} \
--query "SecurityGroups[0].GroupId" --output text)
```

iii. Add `POD_SG` to RDS security group to allow access:

```bash
$ aws ec2 authorize-security-group-ingress \
--group-id ${NETWORKING_RDS_SG_ID} \
--protocol tcp \
--port 5432 \
--source-group ${POD_SG}
```

### Enable DNS

Our application would rely on DNS to reach the RDS instance. Now that we have a created a security group intended for our application pod, we need to adjust the worker node security group to allow DNS resolution to work from the pod security group. Use the following command to locate the cluster security group:

```bash
$ export CLUSTER_SG=$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} \
--query "cluster.resourcesVpcConfig.clusterSecurityGroupId" \
--output text)
```

Allow POD_SG to connect to CLUSTER_SG using TCP and UDP ports 53:

```bash
$ aws ec2 authorize-security-group-ingress \
    --group-id ${CLUSTER_SG} \
    --protocol tcp \
    --port 53 \
    --source-group ${POD_SG}

$ aws ec2 authorize-security-group-ingress \
    --group-id ${CLUSTER_SG} \
    --protocol udp \
    --port 53 \
    --source-group ${POD_SG}
```
