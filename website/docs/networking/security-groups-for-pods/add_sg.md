---
title: "Applying a Security Group"
sidebar_position: 40
hide_table_of_contents: true
---
 
In order for our catalog Pod to successfully connect to the RDS instance we'll need to use the correct security group. Although this security group could be applied to the EKS worker nodes themselves, this would result in any workload in our cluster having network access to the RDS instance. Instead we'll apply Security Groups for Pods to specifically allow our catalog Pods access to the RDS instance.

A security group which allows access to the RDS database has already been set up for you, and we can view it like so:

```bash
$ aws ec2 describe-security-groups \
  --group-ids $CATALOG_SG_ID | jq '.'
{
  "SecurityGroups": [
    {
      "Description": "Applied to catalog application pods",
      "GroupName": "eks-workshop-catalog",
      "IpPermissions": [
        {
          "FromPort": 8080,
          "IpProtocol": "tcp",
          "IpRanges": [
            {
              "CidrIp": "10.42.0.0/16",
              "Description": "Allow inbound HTTP API traffic"
            }
          ],
          "Ipv6Ranges": [],
          "PrefixListIds": [],
          "ToPort": 8080,
          "UserIdGroupPairs": []
        }
      ],
      "OwnerId": "1234567890",
      "GroupId": "sg-037ec36e968f1f5e7",
      "IpPermissionsEgress": [
        {
          "IpProtocol": "-1",
          "IpRanges": [
            {
              "CidrIp": "0.0.0.0/0",
              "Description": "Allow all egress"
            }
          ],
          "Ipv6Ranges": [],
          "PrefixListIds": [],
          "UserIdGroupPairs": []
        }
      ],
      "VpcId": "vpc-077ca8c89d111b3c1"
    }
  ]
}
```

This security group:

- Allows inbound traffic for the HTTP API served by the Pod on port 8080
- Allows all egress traffic
- Will be allowed to access the RDS database as we saw earlier

In order for our Pod to use this security group we need to use the `SecurityGroupPolicy` CRD to tell EKS which security group is to be mapped to a specific set of Pods. This is what we'll configure:

```kustomization
networking/securitygroups-for-pods/sg/policy.yaml
SecurityGroupPolicy/catalog-rds-access
```

Apply this to the cluster then recycle the catalog Pods once again:

```bash
$ kubectl apply -k /workspace/modules/networking/securitygroups-for-pods/sg
namespace/catalog unchanged
serviceaccount/catalog unchanged
configmap/catalog unchanged
configmap/catalog-env-97g7bft95f unchanged
configmap/catalog-sg-env-54k244c6t7 created
secret/catalog-db unchanged
service/catalog unchanged
service/catalog-mysql unchanged
service/ui-nlb unchanged
deployment.apps/catalog unchanged
statefulset.apps/catalog-mysql unchanged
securitygrouppolicy.vpcresources.k8s.aws/catalog-rds-access created
$ kubectl delete pod -n catalog -l app.kubernetes.io/component=service
pod "catalog-6ccc6b5575-glfxc" deleted
$ kubectl rollout status -n catalog deployment/catalog --timeout 30s
deployment "catalog" successfully rolled out
```

This time the catalog Pod will start and the rollout will succeed. You can check the logs to confirm its connecting to the RDS database:

```bash
$ kubectl -n catalog logs deployment/catalog | grep Connecting
2022/12/20 20:52:10 Connecting to catalog_user:xxxxxxxxxx@tcp(eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306)/catalog?timeout=5s
2022/12/20 20:52:10 Connecting to catalog_user:xxxxxxxxxx@tcp(eks-workshop-catalog.cjkatqd1cnrz.us-west-2.rds.amazonaws.com:3306)/catalog?timeout=5s
```
