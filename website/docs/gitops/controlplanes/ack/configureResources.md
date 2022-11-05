---
title: "Provision ACK Resources"
sidebar_position: 3
---

## Create RDS Database

Set new password
```bash
$ kubectl create secret generic "${CATALOG_INSTANCE_NAME}" --from-literal=password="$(date +%s | sha256sum | base64 | head -c 32)" --namespace default
```

```file
ack/rds/resources/rds-security-group.yaml
```
```file
ack/rds/resources/rds-dbgroup.yaml
```
```file
ack/rds/resources/rds-instance.yaml
```

Create SecurityGroup, DBSubnetGroup, and DBInstance
```bash timeout=600
$ kubectl apply -k /workspace/modules/ack/rds/resources
$ kubectl wait DBInstance rds-eks-workshop --for=condition=ACK.ResourceSynced --timeout=10m
```

## Create Amazon MQ Broker 

Set instance name
```bash
$ ORDERS_INSTANCE_NAME=mq-eks-workshop
```
Set namespace
```bash
$ ORDERS_NAMESPACE=orders-prod
```
Set new password
```bash
$ ORDERS_PASSWORD="$(date +%s | sha256sum | base64 | head -c 32)"
```
Create secret
```bash
$ kubectl create secret generic "${ORDERS_INSTANCE_NAME}" --from-literal=password="${ORDERS_PASSWORD}" --namespace default
```

Create Security Group yaml
```bash
$ cat <<EOF > mq-security-group.yaml
apiVersion: ec2.services.k8s.aws/v1alpha1
kind: SecurityGroup
metadata:
  name: "${ORDERS_INSTANCE_NAME}"
  namespace: default
spec:
  description: SecurityGroup ${ORDERS_INSTANCE_NAME}
  name: ${ORDERS_INSTANCE_NAME}
  vpcID: $(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${EKS_CLUSTER_NAME}-vpc" --query 'Vpcs[0].VpcId')
  ingressRules:
  - ipProtocol: tcp
    ipRanges:
    - cidrIP: "0.0.0.0/0"
    fromPort: 61616
    toPort: 61619
  - ipProtocol: tcp
    ipRanges:
    - cidrIP: "0.0.0.0/0"
    fromPort: 8162
    toPort: 8162
EOF
```

Create Security Group resource
```bash
$ kubectl apply -f mq-security-group.yaml
```

Wait for Security Group to be created
```bash
$ kubectl wait SecurityGroup ${ORDERS_INSTANCE_NAME} --for=condition=ACK.ResourceSynced
```

Get the Security Group ID
```bash
$ ORDERS_SECURITY_GROUP_ID=$(kubectl get SecurityGroup ${ORDERS_INSTANCE_NAME} -o go-template='{{.status.id}}')
```

Create Broker yaml
```bash
$ cat <<EOF > mq-broker.yaml
apiVersion: mq.services.k8s.aws/v1alpha1
kind: Broker
metadata:
  name: "${ORDERS_INSTANCE_NAME}"
spec:
  name: "${ORDERS_INSTANCE_NAME}"
  deploymentMode: SINGLE_INSTANCE
  engineType: ActiveMQ
  engineVersion: "5.15.8"
  hostInstanceType: "mq.t3.micro"
  publiclyAccessible: false
  autoMinorVersionUpgrade: false
  users:
    - password:
        namespace: default
        name: "${ORDERS_INSTANCE_NAME}"
        key: password
      groups: []
      consoleAccess: true
      username: admin
  subnetIDs:
  - $(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/cluster/$EKS_CLUSTER_NAME" "Name=map-public-ip-on-launch,Values=false" --query 'Subnets[0].SubnetId')
  securityGroups:
  - ${ORDERS_SECURITY_GROUP_ID}
EOF
```
 
Create Broker resource
```bash
$ kubectl apply -f mq-broker.yaml
```

Wait for Broker to be created
```bash
$ kubectl wait Broker ${ORDERS_INSTANCE_NAME} --for=condition=ACK.ResourceSynced --timeout=20m
```

