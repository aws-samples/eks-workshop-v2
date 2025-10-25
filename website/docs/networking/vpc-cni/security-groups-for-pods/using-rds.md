---
title: "Using Amazon RDS"
sidebar_position: 20
---

An RDS database has been created in our account. Let's retrieve its endpoint and password to be used later:

```bash
$ export CATALOG_RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $EKS_CLUSTER_NAME-catalog | jq -r '.DBInstances[0].Endpoint.Address')
$ echo $CATALOG_RDS_ENDPOINT
eks-workshop-catalog.cluster-cjkatqd1cnrz.us-west-2.rds.amazonaws.com
$ export CATALOG_RDS_PASSWORD=$(aws ssm get-parameter --name $EKS_CLUSTER_NAME-catalog-db --region $AWS_REGION --query "Parameter.Value" --output text --with-decryption)
```

The first step in this process is to re-configure the catalog service to use an Amazon RDS database that has already been created. The application loads most of its configuration from a ConfigMap. Let's take a look at it:

```bash
$ kubectl -n catalog get -o yaml cm catalog
apiVersion: v1
data:
  RETAIL_CATALOG_PERSISTENCE_DB_NAME: catalog
  RETAIL_CATALOG_PERSISTENCE_ENDPOINT: catalog-mysql:3306
  RETAIL_CATALOG_PERSISTENCE_PROVIDER: mysql
kind: ConfigMap
metadata:
  name: catalog
  namespace: catalog
```

The following kustomization overwrites the ConfigMap, altering the MySQL endpoint so that the application will connect to the Amazon RDS database that's been created already for us, which is being pulled from the environment variable `CATALOG_RDS_ENDPOINT`:

```kustomization
modules/networking/securitygroups-for-pods/rds/kustomization.yaml
ConfigMap/catalog
```

Let's apply this change to use the RDS database:

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/networking/securitygroups-for-pods/rds \
  | envsubst | kubectl apply -f-
```

Check that the ConfigMap has been updated with the new values:

```bash
$ kubectl get -n catalog cm catalog -o yaml
apiVersion: v1
data:
  RETAIL_CATALOG_PERSISTENCE_DB_NAME: catalog
  RETAIL_CATALOG_PERSISTENCE_ENDPOINT: eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306
  RETAIL_CATALOG_PERSISTENCE_PROVIDER: mysql
kind: ConfigMap
metadata:
  labels:
    app: catalog
  name: catalog
  namespace: catalog
```

Now we need to recycle the catalog Pods to pick up our new ConfigMap contents:

```bash expectError=true
$ kubectl delete pod -n catalog -l app.kubernetes.io/component=service
pod "catalog-788bb5d488-9p6cj" deleted
$ kubectl rollout status -n catalog deployment/catalog --timeout 30s
Waiting for deployment "catalog" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
```

We got an error - it looks like our catalog Pods failed to restart in time. What's gone wrong? Let's check the Pod logs to see what happened:

```bash
$ kubectl -n catalog logs deployment/catalog
Using mysql database eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306

2025/05/06 05:52:02 /appsrc/repository/repository.go:32
[error] failed to initialize database, got error dial tcp 10.42.179.30:3306: i/o timeout
panic: failed to connect database
```

Our Pod is unable to connect to the RDS database. We can check the EC2 Security Group that's been applied to the RDS database like so:

```bash
$ aws ec2 describe-security-groups \
    --filters Name=vpc-id,Values=$VPC_ID Name=tag:Name,Values=$EKS_CLUSTER_NAME-catalog-rds | jq '.'
{
  "SecurityGroups": [
    {
      "Description": "Catalog RDS security group",
      "GroupName": "eks-workshop-catalog-rds-20221220135004125100000005",
      "IpPermissions": [
        {
          "FromPort": 3306,
          "IpProtocol": "tcp",
          "IpRanges": [],
          "Ipv6Ranges": [],
          "PrefixListIds": [],
          "ToPort": 3306,
          "UserIdGroupPairs": [
            {
              "Description": "MySQL access from within VPC",
              "GroupId": "sg-037ec36e968f1f5e7",
              "UserId": "1234567890"
            }
          ]
        }
      ],
      "OwnerId": "1234567890",
      "GroupId": "sg-0b47cdc59485262ea",
      "IpPermissionsEgress": [],
      "Tags": [
        {
          "Key": "Name",
          "Value": "eks-workshop-catalog-rds"
        }
      ],
      "VpcId": "vpc-077ca8c89d111b3c1"
    }
  ]
}
```

You can also view the security group of the RDS instance through the AWS console:

<ConsoleButton url="https://console.aws.amazon.com/rds/home#database:id=eks-workshop-catalog;is-cluster=false" service="rds" label="Open RDS console"/>

This security group only allows traffic to access the RDS database on port `3306` if it comes from a source which has a specific security group, in the example above `sg-037ec36e968f1f5e7`.
