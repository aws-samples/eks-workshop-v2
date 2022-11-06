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
```bash timeout=1020
$ kubectl apply -k /workspace/modules/ack/rds/k8s
$ kubectl wait SecurityGroup rds-eks-workshop --for=condition=ACK.ResourceSynced --timeout=1m
$ kubectl wait DBSubnetGroup rds-eks-workshop --for=condition=ACK.ResourceSynced --timeout=1m
$ kubectl wait DBInstance rds-eks-workshop --for=condition=ACK.ResourceSynced --timeout=15m
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
```bash timeout=1080
$ export ORDERS_SECURITY_GROUP_ID=$(kubectl get SecurityGroup mq-eks-workshop -o go-template='{{.status.id}}')
$ kubectl apply -k /workspace/modules/ack/mq/k8s/broker
$ kubectl wait brokers.mq.services.k8s.aws mq-eks-workshop --for=condition=ACK.ResourceSynced --timeout=18m
```

