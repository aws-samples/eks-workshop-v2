---
title: "Missing Worker Nodes"
sidebar_position: 71
chapter: true
sidebar_custom_props: { "module": true }
---

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=30
$ prepare-environment troubleshooting/workernodes/one
```

The preparation of the lab might take a couple of minutes and it will make the following changes to your lab environment:

- Create a new managed node group called **_new_nodegroup_1_**
- Introduce a problem to the managed node group which causes node to **_not join_**
- Set desired managed node group count to 1

:::

### Background

Corporation XYZ is launching a new e-commerce platform in the us-west-2 region using an EKS cluster running Kubernetes version 1.30. During a security review, several gaps were identified in the cluster's security posture, particularly around node group volume encryption and AMI customization.

The security team provided specific requirements including:
  - Enabling encryption for node group volumes
  - Setting up best practice network configurations
  - Ensuring EKS Optimized AMIs are used
  - Enabling Kubernetes auditing


Sam, an engineer with Kubernetes experience but new to EKS, created a new managed node group named *new_nodegroup_1* to implement these requirements. However, no new nodes are joining the cluster despite the node group creation appearing successful. Initial checks of the EKS cluster status, node group configuration, and Kubernetes events haven't revealed any obvious issues.

### Step 1: Verify Node Status

Let's first verify Sam's observation about the missing nodes:

```bash expectError=true timeout=60 hook=fix-1-1 hookTimeout=120
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
No resources found
```

:::note
This confirms Sam's observation - no nodes are present from the new nodegroup (new_nodegroup_1).
:::

### Step 2: Check Managed Node Group Status

Since Managed Node Groups are responsible for creating nodes, let's examine the nodegroup details. Key aspects to check:
- Node group existence
- Status and health
- Desired size


```bash
$ aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_1
```

:::info
You can also view this information in the EKS Console:
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#clusters/eks-workshop?selectedTab=cluster-compute-tab"
  service="eks"
  label="Open EKS Cluster Compute Tab"
/>
:::

### Step 3: Analyze Node Group Health Status

The nodegroup should eventually transition to a DEGRADED state. Let's examine the detailed status:

```bash
$ aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_1 --query 'Nodegroup.{NodegroupName:NodegroupName,Status:Status,ScalingConfig:ScalingConfig,AutoScalingGroups:Resources.AutoScalingGroups,Health:Health}'

{
    "nodegroup": {
        "nodegroupName": "new_nodegroup_1", <<<---
        "nodegroupArn": "arn:aws:eks:us-west-2:1234567890:nodegroup/eks-workshop/new_nodegroup_1/abcd1234-1234-abcd-1234-1234abcd1234",
        "clusterName": "eks-workshop",
        ...
        "status": "DEGRADED",               <<<---
        "capacityType": "ON_DEMAND",
        "scalingConfig": {
            "minSize": 0,
            "maxSize": 1,
            "desiredSize": 1                <<<---
        },
        ...
        "resources": {
            "autoScalingGroups": [
                {
                    "name": "eks-new_nodegroup_1-abcd1234-1234-abcd-1234-1234abcd1234"
                }
            ]
        },
        "health": {                         <<<---
            "issues": [
                {
                    "code": "AsgInstanceLaunchFailures",
                    "message": "Instance became unhealthy while waiting for instance to be in InService state. Termination Reason: Client.InvalidKMSKey.InvalidState: The KMS key provided is in an incorrect state",
                    "resourceIds": [
                        "eks-new_nodegroup_1-abcd1234-1234-abcd-1234-1234abcd1234"
                    ]
                }
            ]
        }
        ...
}
```
:::note
The health status reveals a KMS key issue preventing instance launches. This aligns with Sam's attempt to implement volume encryption.
:::

### Step 4: Investigate Auto Scaling Group Activities

Let's examine the ASG activities to understand the launch failures:

:::info
Note: For your convenience, the Autoscaling Group name is available as env variable $NEW_NODEGROUP_1_ASG_NAME.
:::


```bash
$ aws autoscaling describe-scaling-activities --auto-scaling-group-name ${NEW_NODEGROUP_1_ASG_NAME}

{
    "Activities": [
        {
            "ActivityId": "1234abcd-1234-abcd-1234-1234abcd1234",
            "AutoScalingGroupName": "eks-new_nodegroup_1-abcd1234-1234-abcd-1234-1234abcd1234",
            "Description": "Launching a new EC2 instance: i-1234abcd1234abcd1.  Status Reason: Instance became unhealthy while waiting for instance to be in InService state. Termination Reason: Client.InvalidKMSKey.InvalidState: The KMS key provided is in an incorrect state",
            "Cause": "At 2024-10-04T18:06:36Z an instance was started in response to a difference between desired and actual capacity, increasing the capacity from 0 to 1.",
            ...
            "StatusCode": "Cancelled",
  --->>>    "StatusMessage": "Instance became unhealthy while waiting for instance to be in InService state. Termination Reason: Client.InvalidKMSKey.InvalidState: The KMS key provided is in an incorrect state"
        },
        ...
    ]
}
```

:::info
You can also view this information in the EKS Console. Click on the Autoscaling group name under the Details tab to view the Autoscaling activities.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/nodegroups/new_nodegroup_1"
  service="eks"
  label="Open EKS cluster Nodegroup Tab"
/>
:::


### Step 5: Examine Launch Template Configuration

Let's check the Launch Template for encryption settings:


1. Find the Launch Template ID from the ASG or managed nodegroup. In this example we will use ASG.

  ```bash
  $ aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names ${NEW_NODEGROUP_1_ASG_NAME} \
  --query 'AutoScalingGroups[0].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateId' \
  --output text
  ```

2. Now we can check the encryption settings.
  :::info
  **Note:** _For your convenience we have added the Launch Template ID as env variable with the variable `$NEW_NODEGROUP_1_LT_ID`._
  :::

  ```bash
  $ aws ec2 describe-launch-template-versions --launch-template-id ${NEW_NODEGROUP_1_LT_ID} --query 'LaunchTemplateVersions[].{LaunchTemplateId:LaunchTemplateId,DefaultVersion:DefaultVersion,BlockDeviceMappings:LaunchTemplateData.BlockDeviceMappings}'

  {
      "LaunchTemplateVersions": [
          {
              "LaunchTemplateId": "lt-1234abcd1234abcd1",
              ...
              "DefaultVersion": true,
              "LaunchTemplateData": {
              ...
                  "BlockDeviceMappings": [
                      {
                          "DeviceName": "/dev/xvda",
                          "Ebs": {
      --->>>                 "Encrypted": true,
      --->>>                 "KmsKeyId": "arn:aws:kms:us-west-2:xxxxxxxxxxxx:key/xxxxxxxxxxxx",
                              "VolumeSize": 20,
                              "VolumeType": "gp2"
                          }
                      }
                  ]
  ```

### Step 6: Verify KMS Key Configuration

1. Let's examine the KMS key status and permissions:

  :::info
  **Note:** _For your convenience we have added the KMS Key ID as env variable with the variable `$NEW_KMS_KEY_ID`._
  :::

```bash
$ aws kms describe-key --key-id ${NEW_KMS_KEY_ID} --query 'KeyMetadata.{KeyId:KeyId,Enabled:Enabled,KeyUsage:KeyUsage,KeyState:KeyState,KeyManager:KeyManager}'

{
    "KeyMetadata": {
        ...
        "KeyId": "1234abcd-1234-abcd-1234-1234abcd1234",
        ...
        "Enabled": true,                                 <<<---
        "Description": "Example KMS CMK",
        "KeyUsage": "ENCRYPT_DECRYPT",
        "KeyState": "Enabled",                           <<<---
        "Origin": "AWS_KMS",
        "KeyManager": "CUSTOMER",
        "CustomerMasterKeySpec": "SYMMETRIC_DEFAULT",
        "KeySpec": "SYMMETRIC_DEFAULT",
        ...
    }
}
```

:::info
You can also view this information in the KMS Console. The key will have an alias called _new_kms_key_alias_ followed by 5 random string (e.g. _new_kms_key_alias_123ab_):

<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/kms/home?region=us-west-2#/kms/keys"
  label="Open KMS Customer managed keys"
/>
:::


2. Check the key policy for the CMK.

```bash
$ aws kms get-key-policy --key-id ${NEW_KMS_KEY_ID} | jq -r '.Policy | fromjson'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
```

:::info
The key policy is missing required permissions for the AutoScaling service role.
:::

### Step 7: Implement Solution

1. Add the required KMS key policy:


```bash
$ NEW_POLICY=$(echo '{"Version":"2012-10-17","Id":"default","Statement":[{"Sid":"EnableIAMUserPermissions","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':root"},"Action":"kms:*","Resource":"*"},{"Sid":"AllowAutoScalingServiceRole","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"},"Action":["kms:Encrypt","kms:Decrypt","kms:ReEncrypt*","kms:GenerateDataKey*","kms:DescribeKey"],"Resource":"*"},{"Sid":"AllowAttachmentOfPersistentResources","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"},"Action":"kms:CreateGrant","Resource":"*","Condition":{"Bool":{"kms:GrantIsForAWSResource":"true"}}}]}') && aws kms put-key-policy --key-id "$NEW_KMS_KEY_ID" --policy-name default --policy "$NEW_POLICY" && aws kms get-key-policy --key-id "$NEW_KMS_KEY_ID" --policy-name default | jq -r '.Policy | fromjson'
```
:::note
The policy will look similar to the below.

```json
{
  "Version": "2012-10-17",
  "Id": "default",
  "Statement": [
    {
      "Sid": "EnableIAMUserPermissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowAutoScalingServiceRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowAttachmentOfPersistentResources",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::1234567890:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      },
      "Action": "kms:CreateGrant",
      "Resource": "*",
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    }
  ]
}
```
:::


2. Scale down the node group:

```bash timeout=90 wait=45
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 --scaling-config desiredSize=0; aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1; if [ $? -eq 0 ]; then echo "Node group scaled down to 0"; else echo "Failed to scale down node group"; exit 1; fi

```
:::info
 This can take up to about 30 seconds.
:::

3. Scale up the node group:



```bash timeout=90 wait=45
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 --scaling-config desiredSize=1 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1; if [ $? -eq 0 ]; then echo "Node group scaled up to 1"; else echo "Failed to scale up node group"; exit 1; fi

```

:::info
 This can take up to about 30 seconds.
:::

### Verification

Let's verify our fix has resolved the issue:

1. Check node group status:

```bash timeout=100 wait=70
$ aws eks describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name new_nodegroup_1 --query 'nodegroup.status' --output text
ACTIVE
```

2. Verify node joining:
```bash timeout=100 wait=10
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-108-252.us-west-2.compute.internal   Ready    <none>   3m9s   v1.30.0-eks-036c24b
```

## Key Takeaways

#### Security Implementation
  - Properly configure KMS key policies when implementing encryption
  - Ensure service roles have necessary permissions
  - Validate security configurations before deployment

#### Troubleshooting Process
  - Follow the resource chain (Node → Node Group → ASG → Launch Template)
  - Check health status and error messages at each level
  - Verify service role permissions

#### Best Practices
  - Test security implementations in non-production environments
  - Document required permissions for service roles
  - Implement proper error handling and monitoring

#### Additional Resources

  - [EBS Encryption Key Policy](https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access)
  - [EKS Launch Templates](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html)
  - [Specifying an AMI](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami)
  - [Troubleshooting Worker Node Join Failures - AWS Doc](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#worker-node-fail)
  - [Troubleshooting Worker Node Join Failures - Knowledge Center](https://repost.aws/knowledge-center/eks-worker-nodes-cluster)

