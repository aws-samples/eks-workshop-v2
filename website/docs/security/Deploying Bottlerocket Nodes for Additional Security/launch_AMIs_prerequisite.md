---
title: "Prerequisites to launch Bottlerocket on AWS"
sidebar_position: 50
---

## Amazon provides official AMIs in the following AWS regions:

```
| Region Name               |            Region     |
| -------------             |         ------------- |
| Africa (Cape Town)        |            ap-east-1  |
| Asia Pacific (Hong Kong)  |            ap-east-1  |
| Asia Pacific (Tokyo)      |       ap-northeast-1  |
| Asia Pacific (Seoul)      |       ap-northeast-2  |
| Asia Pacific (Osaka)      |       ap-northeast-3  |
| Asia Pacific (Mumbai)     |           ap-south-1  |
| Asia Pacific (Singapore)  |       ap-southeast-1  |
| Asia Pacific (Sydney)     |       ap-southeast-2  |
| Canada (Central)          |         ca-central-1  |
| Europe (Frankfurt)        |         eu-central-1  |
| Europe (Stockholm)        |           eu-north-1  |
| Europe (Milan)            |           eu-south-1  |
| Europe (Ireland)          |            eu-west-1  |
| Europe (London)           |            eu-west-2  |
| Europe (Paris)            |            eu-west-3  |
| Middle East (Bahrain)     |           me-south-1  |
| South America (São Paulo) |            sa-east-1  |
| US East (N. Virginia)     |            us-east-1  |
| US East (Ohio)            |            us-east-2  |
| US West (N. California)   |            us-west-1  |
| US West (Oregon)          |            us-west-2  |
```

!!! **Note** : AMI ID will vary depends upon on the AWS region, to verify you can use the below command (change region and cluster version as per your requirement) and do not continue the lab unless you can use one of the above regions

```bash 
$ aws ssm get-parameter --region us-east-1 --name "/aws/service/bottlerocket/aws-k8s-1.23/x86_64/latest/image_id" --query Parameter.Value --output text
```