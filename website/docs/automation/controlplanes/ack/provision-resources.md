---
title: "Provision ACK Resources"
sidebar_position: 5
---

By default the catalog component in the sample application uses a MySQL database running as a pod in the EKS cluster. In this lab, we'll provision an Amazon RDS database for our application using Kubernetes custom resources to specify the desired configuration required by the workload.

![ACK reconciler concept](./assets/ack-desired-current.jpg)

The first thing we need to do is create a Kubernetes secret that'll be used to provide the master password for the RDS database. We'll configure ACK to read this secret as a source for the password:

```bash hook=create-secret
$ kubectl create secret generic catalog-rds-pw \
  --from-literal=password="$(date +%s | sha256sum | base64 | head -c 32)" -n catalog
secret/catalog-rds-pw created
```

Now let's explore the various ACK resources that we'll create. The first is an EC2 security group that will be applied to control access to the RDS database, which is done with a `SecurityGroup` resource:

```file
automation/controlplanes/ack/rds/k8s/rds-security-group.yaml
```

:::info

The EC2 security group above allows any traffic from the CIDR range of the VPC used by the EKS cluster. This has been done to keep the example clear and understandable. A more secure approach would be to use [Security Groups for Pods](../../../networking/security-groups-for-pods/index.md) to allow traffic from specific pods.

:::

Next we want the RDS database to use the private subnets in our VPC. To accomplish this, we'll create a `DBSubnetGroup` which selects the appropriate subnet IDs:

```file
automation/controlplanes/ack/rds/k8s/rds-dbgroup.yaml
```

Finally, we can create the configuration for the RDS database itself with a `DBInstance` resource:

```file
automation/controlplanes/ack/rds/k8s/rds-instance.yaml
```

Apply this configuration to the Amazon EKS cluster:

```bash wait=30
$ kubectl apply -k /workspace/modules/automation/controlplanes/ack/rds/k8s
securitygroup.ec2.services.k8s.aws/rds-eks-workshop created
dbinstance.rds.services.k8s.aws/rds-eks-workshop created
dbsubnetgroup.rds.services.k8s.aws/rds-eks-workshop created
```

The ACK controllers in the cluster will react to these new resources and provision the AWS infrastructure it has expressed. For example, we can use the AWS CLI to query the RDS database:

```bash
$ aws rds describe-db-instances \
    --db-instance-identifier ${EKS_CLUSTER_NAME}-catalog-ack
```

It takes some time to provision the AWS managed services, in the case of RDS up to 10 minutes. The AWS provider controller will report the status of the reconciliation in the status field of the Kubernetes custom resources.

```bash
$ kubectl get dbinstances.rds.services.k8s.aws ${EKS_CLUSTER_NAME}-catalog-ack -n catalog -o yaml | yq '.status'
```

We can use this status field to instruct `kubectl` to wait until the RDS database has been successfully created:

```bash timeout=1080
$ kubectl wait dbinstances.rds.services.k8s.aws ${EKS_CLUSTER_NAME}-catalog-ack \
  -n catalog --for=condition=ACK.ResourceSynced --timeout=15m
dbinstances.rds.services.k8s.aws/rds-eks-workshop condition met
```
