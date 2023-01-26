---
title: "Using Amazon RDS"
sidebar_position: 20
---

The first step in this process is to re-configure the catalog service to use an Amazon RDS dabase that has already been created. The application loads most of its configuration from a ConfigMap, lets take look at it:

```bash
$ kubectl -n catalog get -o yaml cm catalog
apiVersion: v1
data:
  DB_ENDPOINT: catalog-mysql:3306
  DB_READ_ENDPOINT: catalog-mysql:3306
kind: ConfigMap
metadata:
  name: catalog
  namespace: catalog
```

The following kustomization overwrites the ConfigMap, altering the MySQL endpoint so that the application will connect to the Amazon RDS database thats been created already for us which is being pulled from the environment variable `CATALOG_RDS_ENDPOINT`.

```kustomization
networking/securitygroups-for-pods/rds/kustomization.yaml
ConfigMap/catalog
```

Let's check the value of `CATALOG_RDS_ENDPOINT` then run Kustomize to use the real DynamoDB service:

```bash
$ echo $CATALOG_RDS_ENDPOINT
eks-workshop-catalog.cluster-cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306
$ kubectl apply -k /workspace/modules/networking/securitygroups-for-pods/rds
```

Check that the ConfigMap has been updated with the new values:

```bash
$ kubectl get -n catalog cm catalog -o yaml
apiVersion: v1
data:
  DB_ENDPOINT: eks-workshop-catalog.cluster-cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306
  DB_READ_ENDPOINT: eks-workshop-catalog.cluster-cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306
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

We got an error, it looks like our catalog Pods failed to restart in time. What's gone wrong? Let's check the Pod logs to see what happened:

```bash
$ kubectl -n catalog logs deployment/catalog
2022/12/19 17:43:05 Error: Failed to prep migration dial tcp 10.42.11.72:3306: i/o timeout
2022/12/19 17:43:05 Error: Failed to run migration dial tcp 10.42.11.72:3306: i/o timeout
2022/12/19 17:43:05 dial tcp 10.42.11.72:3306: i/o timeout
```

Our Pod is unable to connect to the RDS database. We can check the EC2 Security Group thats been applied to the RDS database like so:

```bash
$ aws ec2 describe-security-groups \
    --group-ids "$CATALOG_RDS_SG_ID" | jq '.'
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

https://console.aws.amazon.com/rds/home#database:id=eks-workshop-catalog;is-cluster=false

This security group only allows traffic to access the RDS database on port `3306` if it comes from a source which has a specific security group, in the example above `sg-037ec36e968f1f5e7`.
