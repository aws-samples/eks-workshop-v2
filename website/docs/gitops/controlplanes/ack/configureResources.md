---
title: "Provision ACK Resources"
sidebar_position: 3
---

## Create RDS Database

Set DB master user password
```bash
$ kubectl create secret generic rds-eks-workshop --from-literal=password="$(date +%s | sha256sum | base64 | head -c 32)" --namespace default
```

Security Group manifest
```file
ack/rds/k8s/rds-security-group.yaml
```
RDS DBSubnetGroup manifest
```file
ack/rds/k8s/rds-dbgroup.yaml
```
RDS DBInstance manifest
```file
ack/rds/k8s/rds-instance.yaml
```

Create SecurityGroup, DBSubnetGroup, and DBInstance
```bash
$ kubectl apply -k /workspace/modules/ack/rds/k8s
```
## Create Amazon MQ Broker 


Security Group manifest
```file
ack/mq/k8s/security-group/mq-security-group.yaml
```

Create Security Group for MQ Broker
```bash
$ kubectl apply -k /workspace/modules/ack/mq/k8s/security-group
$ kubectl wait SecurityGroup mq-eks-workshop --for=condition=ACK.ResourceSynced --timeout=1m
```


Create secret for admin user
```bash
$ kubectl create secret generic mq-eks-workshop --from-literal=password="$(date +%s | sha256sum | base64 | head -c 32)" --namespace default
```

Amazon MQ Broker manifest
```file
ack/mq/k8s/broker/mq-broker.yaml
```

Create Amazon MQ Broker
```bash
$ export ORDERS_SECURITY_GROUP_ID=$(kubectl get SecurityGroup mq-eks-workshop -o go-template='{{.status.id}}')
$ kubectl apply -k /workspace/modules/ack/mq/k8s/broker
```

### Verify the AWS Managed Services

It takes some time to provision the AWS managed services, for RDS and MQ approximately 10 minutes. The ACK controller will report the status of the reconciliation in the status field of the Kubernetes custom resources.  
You can open the AWS console and see the services being created.

To verify that the provision is done, you can check that the condition “ACK.ResourceSynced” is true using the Kubernetes CLI.

Run the following commands and they will exit once the condition is met.

Verify the AWS managed services are ready
```bash timeout=1080
$ kubectl wait DBInstance rds-eks-workshop --for=condition=ACK.ResourceSynced --timeout=15m
$ kubectl wait brokers.mq.services.k8s.aws mq-eks-workshop --for=condition=ACK.ResourceSynced --timeout=18m
```

Continue to the next section to export the binding information from the provisioned AWS managed services.

