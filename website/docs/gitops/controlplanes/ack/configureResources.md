---
title: "Provision ACK Resources"
sidebar_position: 3
---

In this section we will provision a database and message broker for our application, we will use AWS managed services.
AWS managed service can be provision using Kubernetes API, we will use Kubernetes custom resources to specify the desire
configuration for the service we want to access form our application.

## Create RDS Database

Set DB master user password
```bash
$ kubectl create secret generic rds-eks-workshop --from-literal=password="$(date +%s | sha256sum | base64 | head -c 32)" --namespace default
secret/rds-eks-workshop created
```

Specify a Security Group manifest, this controls access to our database.
```file
ack/rds/k8s/rds-security-group.yaml
```
Specify a RDS DBSubnetGroup manifest, this configures the subnets that the database will be attach
```file
ack/rds/k8s/rds-dbgroup.yaml
```
Specify a RDS DBInstance manifest, this configures the database configuration like storage and engine.
```file
ack/rds/k8s/rds-instance.yaml
```

Create SecurityGroup, DBSubnetGroup, and DBInstance using the manifest files.
```bash
$ kubectl apply -k /workspace/modules/ack/rds/k8s
securitygroup.ec2.services.k8s.aws/rds-eks-workshop created
dbinstance.rds.services.k8s.aws/rds-eks-workshop created
dbsubnetgroup.rds.services.k8s.aws/rds-eks-workshop created
```
## Create Amazon MQ Broker 


Specify a Security Group manifest, this controls access to our message broker.
```file
ack/mq/k8s/security-group/mq-security-group.yaml
```

Create Security Group for MQ Broker using the manifest file.
```bash
$ kubectl apply -k /workspace/modules/ack/mq/k8s/security-group
securitygroup.ec2.services.k8s.aws/mq-eks-workshop created
```
Wait until the security group is reconciled
```bash
$ kubectl wait SecurityGroup mq-eks-workshop --for=condition=ACK.ResourceSynced --timeout=1m
securitygroup.ec2.services.k8s.aws/mq-eks-workshop condition met
```


Set admin user password
```bash
$ kubectl create secret generic mq-eks-workshop --from-literal=password="$(date +%s | sha256sum | base64 | head -c 32)" --namespace default
secret/mq-eks-workshop created
```

Specify the Amazon MQ Broker manifest
```file
ack/mq/k8s/broker/mq-broker.yaml
```

Create Amazon MQ Broker using the manifest files.
```bash
$ export ORDERS_SECURITY_GROUP_ID=$(kubectl get SecurityGroup mq-eks-workshop -o go-template='{{.status.id}}')
$ kubectl apply -k /workspace/modules/ack/mq/k8s/broker
broker.mq.services.k8s.aws/mq-eks-workshop created
```

### Verify the AWS Managed Services

It takes some time to provision the AWS managed services, for RDS and MQ approximately 10 minutes. The ACK controller will report the status of the reconciliation in the status field of the Kubernetes custom resources.  
You can open the AWS console and see the services being created.

To verify that the provision is done, you can check that the condition “ACK.ResourceSynced” is true using the Kubernetes CLI.

Run the following commands and they will exit once the condition is met.

Wait until the RDS Database is created
```bash timeout=1080
$ kubectl wait DBInstance rds-eks-workshop --for=condition=ACK.ResourceSynced --timeout=15m
dbinstances.rds.services.k8s.aws/rds-eks-workshop condition met
```

Wait until the MQ Broker is created
```bash timeout=1080
$ kubectl wait brokers.mq.services.k8s.aws mq-eks-workshop --for=condition=ACK.ResourceSynced --timeout=18m
brokers.mq.services.k8s.aws/mq-eks-workshop condition met
```

Continue to the next section to export the binding information from the provisioned AWS managed services.

