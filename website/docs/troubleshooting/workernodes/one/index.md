---
title: "Missing Worker Nodes"
sidebar_position: 30
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

Corporate XYZ is in the process of launching a new e-commerce platform in the us-west-2 region. The EKS cluster running the platform is using Kubernetes version 1.30. During a recent security review, the security team identified several gaps in the cluster's security posture, including the need for encryption of node group volumes as they plan customize the AMI.

The security team has provided specific recommendations to Sam, the engineer in charge of enhancing the security of the EKS environment. These include:

- Enabling encryption for the node group volume.
- Setting up best practice network configurations for the cluster.
- Ensuring EKS Optmized AMIs are used.
- Enabling Kubernetes auditing to capture and monitor all activities within the cluster.

Sam, who has prior Kubernetes experience but is new to EKS, has been tasked with addressing these security concerns before the platform's launch next quarter. To start, Sam created a new managed node group named **_new_nodegroup_1_** in the us-west-2 region, but no new nodes have joined the cluster. During the troubleshooting process, Sam has checked the EKS cluster status and the node group configuration, but has not found any obvious errors or issues. The Kubernetes events and logs do not provide any clear indications of the problem either.

Can you help Sam identify the root cause of the node group issue and suggest the necessary steps to resolve the problem, so the new nodes can join the cluster, and the security enhancements can be implemented before the platform's launch?

### Step 1

1. First step here is to confirm and verify what Sam your client has mentioned. Let's go ahead and check for the nodes.

```bash expectError=true timeout=60 hook=fix-1-1 hookTimeout=120
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
No resources found
```

As you can see, there are no resources found for nodes launched from the new nodegroup (new_nodegroup_1).

### Step 2

We know that Sam created a new managed nodegroup called new_node_group_1. Managed Nodegroups are responsible to creating nodes so can follow the chain of command from checking the node in the previous step to checking the nodegroup.

1. First, we want to see if the Managed nodegroup was created and see it's details. Some important and basic details to keep an eye out for are:

   - Does the nodegroup exist?
   - Managed Node Group Status and health
   - Desired size

```bash
$ aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_1
```

:::info
Alternatively, you can also check the console for the same. Click the button below to open the EKS Console.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#clusters/eks-workshop?selectedTab=cluster-compute-tab"
  service="eks"
  label="Open EKS Cluster Compute Tab"
/>
:::

### Step 3

Depending on how long the managed nodegroup was running for the _status_ of the managed nodegroup could vary, however eventually it should transition to DEGRADED state. If the status is already in the DEGRADED state, you will see the health information for more detail about the reason it is in this state. Whether the status in the DEGRADED or ACTIVE state the issue still remains and we can see that the desired size is set to 1. We expect to see a node, but we do not so we still must find out why.

```bash
$ aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_1 --query 'Nodegroup.{NodegroupName:NodegroupName,Status:Status,ScalingConfig:ScalingConfig,AutoScalingGroups:Resources.AutoScalingGroups,Health:Health}'

$ aws eks describe-nodegroup --cluster-name eks-workshop --nodegroup-name new_nodegroup_1
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

Here is a sample of the output for an ACTIVE status:

```json {7,15-16}
{
    "nodegroup": {
        "nodegroupName": "new_nodegroup_1",
        "nodegroupArn": "arn:aws:eks:us-west-2:1234567890:nodegroup/eks-workshop/new_nodegroup_1/abcd1234-1234-abcd-1234-1234abcd1234",
        "clusterName": "eks-workshop",
        ...
        "status": "ACTIVE",
        "capacityType": "ON_DEMAND",
        "scalingConfig": {
            "minSize": 0,
            "maxSize": 1,
            "desiredSize": 1
        },
        ...
        "health": {
            "issues": []

```

Now that we've confirmed that the nodegroup exists, following the same chain of command logic we can narrow this down further by checking the Autoscaling Group (ASG) which is the AWS component that performs scaling activities for the node. Let's describe the scaling activities for the Autoscaling Group.

:::info
**Note:** _For your convenience we have added the Autoscaling Group name as env variable with the variable `$NEW_NODEGROUP_1_ASG_NAME`._
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
Alternatively, you can also check the console for the same. Click the button below to open the EKS Console. You can find the Autoscaling group name under the Details tab of the node group. Then you can click the Autoscaling group name to redirect to the ASG console. Then click the Activity tab to view the ASG activty history.
<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/eks-workshop/nodegroups/new_nodegroup_1"
  service="eks"
  label="Open EKS cluster Nodegroup Tab"
/>
:::

As you can see from the _StatusMessage_, the termination reason was due to **_Client.InvalidKMSKey.InvalidState_**. This seems to indicate and issue with the KMS key which was can be used to encrypted EBS volumes.

### Step 4

Let's now dig deeper into the ASG by checking the Launch Template used to create the instances.

1. You can find the Launch Template ID from the ASG or managed nodegroup. In this example we will use the ASG.

   ```bash
   $ aws autoscaling describe-auto-scaling-groups \
   --auto-scaling-group-names ${NEW_NODEGROUP_1_ASG_NAME} \
   --query 'AutoScalingGroups[0].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateId' \
   --output text
   ```

2. Now we can check the Launch Template contents for any hints of KMS configurations.
   :::info
   **Note:** _For your convenience we have added the Launch Template ID as env variable with the variable `$NEW_NODEGROUP_1_LT_ID`._
   :::

   ```bash
   $ aws ec2 describe-launch-template-versions --launch-template-id <LAUNCH_TEMPLATE_ID> --query 'LaunchTemplateVersions[].{LaunchTemplateId:LaunchTemplateId,DefaultVersion:DefaultVersion,BlockDeviceMappings:LaunchTemplateData.BlockDeviceMappings}'

   $ aws ec2 describe-launch-template-versions --launch-template-id ${NEW_NODEGROUP_1_LT_ID} --versions $Default
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

### Step 5

The volume is encrypted with a KMS Key ID specified. To see more details about the KMS let's run a describe command against it.

:::info
**Note:** _For your convenience we have added the KMS Key ID as env variable with the variable `$NEW_KMS_KEY_ID`._
:::

```bash
$ aws kms describe-key --key-id ${NEW_KMS_KEY_ID} --query 'KeyMetadata.{KeyId:KeyId,Enabled:Enabled,KeyUsage:KeyUsage,KeyState:KeyState,KeyManager:KeyManager}'

$ aws kms describe-key --key-id ${NEW_KMS_KEY_ID}
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
Alternatively, you can also check the console for the same. Click the button below to open the KMS Console for Customer managed keys Console. The key will have an alias called _new_kms_key_alias_ followed by 5 random string (e.g. _new_kms_key_alias_123ab_):

<ConsoleButton
  url="https://us-west-2.console.aws.amazon.com/kms/home?region=us-west-2#/kms/keys"
  label="Open KMS Customer managed keys"
/>
:::

It looks like the key is in **_Enabled_** state. In order to use the KMS Customer Managed Key (CMK), proper permissions must be granted. In our case ASG is responsible for calling the CMK, so the key policy needs to grant proper permissions for the AWSServiceRoleForAutoScaling service-linked role. For more information about this policy you can see the [ASG user guide documentation](https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access).

### Step 6

We can now check the key policy for the CMK.

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

As we can see, we are missing the permissions needed by AWSServiceRoleForAutoScaling service-linked role to use the CMK for encryption. Add the missing permissions.

:::info
The below script is a bash one liner that will add the policy to the variable NEW_POLICY. Then it will run the aws kms put-key-policy to the CMK using the variable as input finishing with a aws kms get-key-policy to verify the change.
:::

```bash
$ NEW_POLICY=$(echo '{"Version":"2012-10-17","Id":"default","Statement":[{"Sid":"EnableIAMUserPermissions","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':root"},"Action":"kms:*","Resource":"*"},{"Sid":"AllowAutoScalingServiceRole","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"},"Action":["kms:Encrypt","kms:Decrypt","kms:ReEncrypt*","kms:GenerateDataKey*","kms:DescribeKey"],"Resource":"*"},{"Sid":"AllowAttachmentOfPersistentResources","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'"$AWS_ACCOUNT_ID"':role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"},"Action":"kms:CreateGrant","Resource":"*","Condition":{"Bool":{"kms:GrantIsForAWSResource":"true"}}}]}') && aws kms put-key-policy --key-id "$NEW_KMS_KEY_ID" --policy-name default --policy "$NEW_POLICY" && aws kms get-key-policy --key-id "$NEW_KMS_KEY_ID" --policy-name default | jq -r '.Policy | fromjson'
```

The policy added should look similar to the below.

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

Finally, we can start up a new node by decreasing the managed node group desired count to 0 and then back to 1.

The script below will modify desiredSize to 0, wait for the nodegroup status to transition from InProgress to Active, then exit. This can take up to about 30 seconds.

```bash timeout=90 wait=60
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 --scaling-config desiredSize=0; aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1; if [ $? -eq 0 ]; then echo "Node group scaled down to 0"; else echo "Failed to scale down node group"; exit 1; fi

{
    "update": {
        "id": "abcd1234-1234-abcd-1234-1234abcd1234",
        "status": "InProgress",
        "type": "ConfigUpdate",
        "params": [
            {
                "type": "DesiredSize",
                "value": "0"
            }
        ],
        "createdAt": "2024-10-23T16:56:03.522000+00:00",
        "errors": []
    }
}
Node group scaled down to 0
```

Once the above command is successful, you can set the desiredSize back to 1. This can take up to about 30 seconds.

```bash timeout=90 wait=60
$ aws eks update-nodegroup-config --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1 --scaling-config desiredSize=1 && aws eks wait nodegroup-active --cluster-name "${EKS_CLUSTER_NAME}" --nodegroup-name new_nodegroup_1; if [ $? -eq 0 ]; then echo "Node group scaled up to 1"; else echo "Failed to scale up node group"; exit 1; fi

{
    "update": {
        "id": "abcd1234-1234-abcd-1234-1234abcd1234",
        "status": "InProgress",
        "type": "ConfigUpdate",
        "params": [
            {
                "type": "DesiredSize",
                "value": "1"
            }
        ],
        "createdAt": "2024-10-23T14:37:41.899000+00:00",
        "errors": []
    }
}
Node group scaled up to 1
```

If all goes well, you will see the nodegroup status change to **ACTIVE** and new node joined on the cluster.

```bash timeout=100 wait=70
$ aws eks describe-nodegroup --cluster-name ${EKS_CLUSTER_NAME} --nodegroup-name new_nodegroup_1 --query 'nodegroup.status' --output text
ACTIVE
```

```bash timeout=100 wait=70
$ kubectl get nodes --selector=eks.amazonaws.com/nodegroup=new_nodegroup_1
NAME                                          STATUS   ROLES    AGE    VERSION
ip-10-42-108-252.us-west-2.compute.internal   Ready    <none>   3m9s   v1.30.0-eks-036c24b
```

## Wrapping it up

In this troubleshooting scenario, we covered one of many issues which can prevent a node from joining a cluster. We covered an issue of improper permissions for the KMS key when encryption is configured to a launch template. Other instances where encryption can be configured are through [ekstcl](https://github.com/eksctl-io/eksctl/blob/main/examples/10-encrypted-volumes.yaml) and when EBS encryption is [enabled by deafult](https://docs.aws.amazon.com/ebs/latest/userguide/encryption-by-default.html). In any case, [Customer Managed Keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk) will require proper permissions for encryption for the AutoScaling service when using EKS Nodegroups.

When customizing Manage Nodegroup bootstrap, it is important to ensure the launch template is configured properly. Further configurations can be made for the Kubelet when specifying an AMI ID to the Launch Template. More information about EKS Launch Templates and Specifying an AMI, see the document below:

- [EKS Launch Templates](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html)
- [Specifying an AMI](https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami)

_Other Related Resources_:

- [EBS Encryption Key Policy](https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access)
- [Troubleshooting Worker Node Join Failures - AWS Doc](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#worker-node-fail)
- [Troubleshooting Worker Node Join Failures - Knowledge Center](https://repost.aws/knowledge-center/eks-worker-nodes-cluster)
