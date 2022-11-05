---
title: "Provision ACK Resources"
sidebar_position: 3
---

## Create RDS Database

Set instance name
```bash
$ CATALOG_INSTANCE_NAME=rds-eks-workshop
```
Set namespace
```bash
$ CATALOG_NAMESPACE=catalog-prod
```
Set new password
```bash
$ CATALOG_PASSWORD="$(date +%s | sha256sum | base64 | head -c 32)"
```
Create secret
```bash
$ kubectl create secret generic "${CATALOG_INSTANCE_NAME}" --from-literal=password="${CATALOG_PASSWORD}" --namespace default
```

Create Security Group yaml
```bash
$ cat <<EOF > rds-security-group.yaml
apiVersion: ec2.services.k8s.aws/v1alpha1
kind: SecurityGroup
metadata:
  name: "${CATALOG_INSTANCE_NAME}"
  namespace: default
spec:
  description: SecurityGroup
  name: ${CATALOG_INSTANCE_NAME}
  vpcID: $(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${EKS_CLUSTER_NAME}-vpc" --query 'Vpcs[0].VpcId')
  ingressRules:
  - ipProtocol: tcp
    ipRanges:
    - cidrIP: "0.0.0.0/0"
    fromPort: 3306
    toPort: 3306
EOF
```

Create Security Group resource
```bash
$ kubectl apply -f rds-security-group.yaml
```

Wait for Security Group to be created
```bash
$ kubectl wait SecurityGroup ${CATALOG_INSTANCE_NAME} --for=condition=ACK.ResourceSynced
```

Create DBSubnetGroup yaml
```bash
$ cat <<EOF > rds-dbgroup.yaml
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBSubnetGroup
metadata:
  name: "${CATALOG_INSTANCE_NAME}"
  namespace: default
spec:
  description: DBSubnet group
  name: ${CATALOG_INSTANCE_NAME}
  subnetIDs:
  - $(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/cluster/$EKS_CLUSTER_NAME" "Name=map-public-ip-on-launch,Values=false" --query 'Subnets[0].SubnetId')
  - $(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/cluster/$EKS_CLUSTER_NAME" "Name=map-public-ip-on-launch,Values=false" --query 'Subnets[1].SubnetId')
  - $(aws ec2 describe-subnets --filters "Name=tag-key,Values=kubernetes.io/cluster/$EKS_CLUSTER_NAME" "Name=map-public-ip-on-launch,Values=false" --query 'Subnets[2].SubnetId')
EOF
```

Create DBSubnetGroup resource
```bash
$ kubectl apply -f rds-dbgroup.yaml
```

Wait for DBSubnetGroup to be created
```bash
$ kubectl wait DBSubnetGroup ${CATALOG_INSTANCE_NAME} --for=condition=ACK.ResourceSynced
```

Create DBInstance yaml
```bash
$ cat <<EOF > rds-mysql.yaml
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBInstance
metadata:
  name: "${CATALOG_INSTANCE_NAME}"
  namespace: default
spec:
  allocatedStorage: 20
  dbInstanceClass: db.t4g.micro
  dbInstanceIdentifier: "${CATALOG_INSTANCE_NAME}"
  engine: mysql
  engineVersion: "8.0"
  masterUsername: "admin"
  dbSubnetGroupRef: 
    from: 
      name: "${CATALOG_INSTANCE_NAME}"
  vpcSecurityGroupRefs:
    - from: 
        name: "${CATALOG_INSTANCE_NAME}"
  masterUserPassword:
    namespace: default
    name: "${CATALOG_INSTANCE_NAME}"
    key: password
  dbName: catalog
EOF
```

Create DBInstance resource
```bash
$ kubectl apply -f rds-mysql.yaml
```

Wait for DBInstance to be created
```bash
$ kubectl wait DBInstance ${CATALOG_INSTANCE_NAME} --for=condition=ACK.ResourceSynced --timeout=20m
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

