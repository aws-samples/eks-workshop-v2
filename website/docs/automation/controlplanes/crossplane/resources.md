---
title: "Managed Resources"
sidebar_position: 20
---

By default the catalog component in the sample application uses a MySQL database running as a pod in the EKS cluster. In this lab, we'll provision an Amazon RDS database for our application using Kubernetes custom resources to specify the desired configuration required by the workload.

Let's explore the various Crossplane resources that we'll create. The first is an EC2 security group that will be applied to control access to the RDS database, which is done with a `ec2.aws.crossplane.io.SecurityGroup` resource:

```file
manifests/modules/automation/controlplanes/crossplane/managed/rds-security-group.yaml
```

:::info

The EC2 security group above allows any traffic from the CIDR range of the VPC used by the EKS cluster. This has been done to keep the example clear and understandable. A more secure approach would be to use [Security Groups for Pods](../../../networking/security-groups-for-pods/index.md) to allow traffic from specific pods.

:::

Next, we want the RDS database to use the private subnets in our VPC. We'll create a `database.aws.crossplane.io.DBSubnetGroup` which selects the appropriate subnet IDs:

```file
manifests/modules/automation/controlplanes/crossplane/managed/rds-dbgroup.yaml
```

Finally, we can create the configuration for the RDS database itself with a `rds.aws.crossplane.io.DBInstance` resource, the master password will be generated in the location specified by `masterUserPasswordSecretRef` since we are
setting `autogeneratePassword: true`, and the `endpoint` and `username` will be populated by `writeConnectionSecretToRef` on the same Kubernetes secret:

```file
manifests/modules/automation/controlplanes/crossplane/managed/rds-instance.yaml
```

Apply this configuration to the EKS cluster:

```bash wait=30
$ kubectl apply -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/managed
dbsubnetgroup.database.aws.crossplane.io/rds-eks-workshop created
securitygroup.ec2.aws.crossplane.io/rds-eks-workshop created
dbinstance.rds.aws.crossplane.io/rds-eks-workshop created
```

The Crossplane controllers in the cluster will react to these new resources and provision the AWS infrastructure it has expressed. For example, we can use the AWS CLI to query the RDS database:

```bash
$ aws rds describe-db-instances \
    --db-instance-identifier ${EKS_CLUSTER_NAME}-catalog-crossplane \
    --output json | jq .
```

It takes some time to provision the AWS managed services, in the case of RDS up to 10 minutes. Crossplane will report the status of the reconciliation in the `status` field of the Kubernetes custom resources.

```bash
$ kubectl get dbinstances.rds.aws.crossplane.io ${EKS_CLUSTER_NAME}-catalog-crossplane -n catalog -o yaml | yq '.status'
```

We can use this `status` field to instruct `kubectl` to wait until the RDS database has been successfully created:

```bash timeout=1200
$ kubectl wait dbinstances.rds.aws.crossplane.io ${EKS_CLUSTER_NAME}-catalog-crossplane \
    --for=condition=Ready --timeout=20m
dbinstances.rds.services.k8s.aws/rds-eks-workshop condition met
```

Crossplane will have automatically created a Kubernetes `Secret` object that contains the credentials to connect to the RDS instance:

```bash
$ kubectl get secret catalog-db-crossplane -n catalog -o yaml
apiVersion: v1
metadata:
  creationTimestamp: "2023-01-26T15:12:41Z"
  name: catalog-db-crossplane
  namespace: catalog
type: connection.crossplane.io/v1alpha1
data:
  endpoint: cmRzLWVrcy13b3Jrc2hvcC5jamthdHFkMWNucnoudXMtd2VzdC0yLnJkcy5hbWF6b25hd3MuY29t
  password: eGRnS1NNN2RSQ3dlc2VvRmhrRUEwWDN3OXpp
  port: MzMwNg==
  username: YWRtaW4=
```

Update the application to use the RDS endpoint and credentials:

```bash
$ kubectl apply -k /eks-workshop/manifests/modules/automation/controlplanes/crossplane/application
namespace/catalog unchanged
serviceaccount/catalog unchanged
configmap/catalog unchanged
secret/catalog-db unchanged
service/catalog unchanged
service/catalog-mysql unchanged
service/ui-nlb created
deployment.apps/catalog configured
statefulset.apps/catalog-mysql unchanged
$ kubectl rollout restart -n catalog deployment/catalog
$ kubectl rollout status -n catalog deployment/catalog --timeout=30s
```

We can now check the logs of the catalog service to verify its connecting to the RDS database provisioned by Crossplane:

```bash
$ kubectl -n catalog logs deployment/catalog
2023/06/02 21:16:18 Running database migration...
2023/06/02 21:16:18 Schema migration applied
2023/06/02 21:16:18 Connecting to eks-workshop-test-catalog-crossplane.cjkatqd1cnrz.us-west-2.rds.amazonaws.com/catalog?timeout=5s
2023/06/02 21:16:18 Connected
2023/06/02 21:16:18 Connecting to eks-workshop-test-catalog-crossplane.cjkatqd1cnrz.us-west-2.rds.amazonaws.com/catalog?timeout=5s
2023/06/02 21:16:18 Connected
```