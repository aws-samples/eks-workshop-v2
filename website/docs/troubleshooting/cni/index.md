---
title: "VPC CNI scenario"
sidebar_position: 40
chapter: true
sidebar_custom_props: { "module": true }
description: "Troubleshooting issues related to EKS VPC CNI IAM policy, IP allocation and scheduling"
---

::required-time

In this section, we will explore techniques for diagnosing and resolving common issues related to the VPC CNI (Virtual Private Cloud Container Network Interface). This hands-on scenario will equip you with practical troubleshooting skills for VPC CNI problems. For a comprehensive understanding of VPC CNI functionality and architecture, please refer to our [Networking module](/docs/networking/vpc-cni), which provides in-depth coverage of the topic.

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=300
$ prepare-environment troubleshooting/cni
```

**Lab Setup Overview:**

This setup process will implement the following modifications:

1. **VPC Configuration**: A secondary CIDR will be added to the existing Virtual Private Cloud.
2. **Subnet Creation**: New subnets will be established within the VPC.
3. **Application Deployment**: A base application will be pre-installed.
4. **Managed Nodegroup Creation**: An additional Managed Nodegroup will be set up in the Amazon EKS cluster.
5. **Troubleshooting Scenario**: A deliberate configuration issue will be introduced for practical troubleshooting throughout the exercise.

:::

You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/cni/.workshop/terraform).

:::info Root Cause Analysis (RCA) Methodology

While the scenario is deployed, feel free to review the _RCA Methodology_.

The Root Cause Analysis (RCA) helps in identifying how and why an event or failure happened, allowing for corrective and preventive measures to be put in place and the RCA generally serves as input to a remediation process whereby corrective actions are taken to prevent the problem from reoccurring.

**_The method steps:_**

1. Identify and describe the problem clearly.
2. Collect data
3. Establish a timeline from the normal situation until the problem occurs.
4. Identify Root Cause
5. Distinguish between the root cause and other causal factors (e.g., using event correlation).
6. Establish a causal graph between the root cause and the problem.
7. Although the word "cause" is singular in RCA, experience shows that generally causes are plural. Therefore, look for multiple causes when carrying out RCA.

:::

Let's confirm the newly created Managed Nodegroup has been properly configured with the specified capacity.

```bash
$ aws eks describe-nodegroup --cluster-name $EKS_CLUSTER_NAME --nodegroup-name cni_troubleshooting_nodes
{
    "nodegroup": {
        "nodegroupName": "cni_troubleshooting_nodes",
        "nodegroupArn": "arn:aws:eks:us-west-2:1234567890:nodegroup/eks-workshop/cni_troubleshooting_nodes/acc9931f-58b2-77c2-7af8-a547204f05ed",
        "clusterName": "eks-workshop",
        "version": "1.30",
        "releaseVersion": "1.30.4-20241109",
        "createdAt": "2024-10-30T18:57:44.538000+00:00",
        "modifiedAt": "2024-10-3018:57:44.538000+00:00",
        "status": "ACTIVE",
        "capacityType": "ON_DEMAND",
        "scalingConfig": {
            "minSize": 1,
            "maxSize": 3,
            "desiredSize": 1
        },
        "instanceTypes": [
            "m5.large"
        ],
        "subnets": [
            "subnet-0b055bfb40a357c1d",
            "subnet-0b450c109787fc1a7",
            "subnet-0de03cca5fade5784"
        ],
        "amiType": "AL2023_x86_64_STANDARD",
        "nodeRole": "arn:aws:iam::1234567890:role/terraform-20241113154725667800000001",
        "labels": {
            "app": "cni_troubleshooting"
        },
        "taints": [
            {
                "key": "purpose",
                "value": "cni_troubleshooting",
                "effect": "NO_SCHEDULE"
            }
        ],
        "diskSize": 20,
        "health": {
            "issues": []
        },
        "updateConfig": {
            "maxUnavailable": 1
        },
        "tags": {}
    }
}
```
Next check the worker node instances are in the running state.

```bash
$ aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/eks-workshop,Values=owned" --query 'Reservations[*].Instances[*].[PrivateDnsName,State.Name]'  --output text
ip-10-42-120-86.us-west-2.compute.internal    running
ip-10-42-139-247.us-west-2.compute.internal   running
ip-10-42-172-120.us-west-2.compute.internal   running
ip-100-64-3-8.us-west-2.compute.internal      running
```

Now, verify the new nodes are joining the cluster.

```bash
$ kubectl get nodes
NAME                                          STATUS     ROLES    AGE   VERSION
ip-10-42-120-86.us-west-2.compute.internal    Ready      <none>   15m   v1.30.0-eks-036c24b
ip-10-42-139-247.us-west-2.compute.internal   Ready      <none>   15m   v1.30.0-eks-036c24b
ip-10-42-172-120.us-west-2.compute.internal   Ready      <none>   15m   v1.30.0-eks-036c24b
ip-100-64-3-8.us-west-2.compute.internal      NotReady   <none>   42s   v1.30.4-eks-a737599
```
Finally, check the base app is deployed.

```bash
$ kubectl get pods -n cni-tshoot
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-5cf4cbfd97-5xbtb   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-6pr6g   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-9td6m   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-ctf9s   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-dgr5z   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-ghx4z   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-gwwmb   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-hjld5   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-hr64c   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-jwjsz   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-l4dpk   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-lhr25   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-qn4g8   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-t8l6l   0/1     Pending   0          10m
nginx-app-5cf4cbfd97-vj56m   0/1     Pending   0          10m
```

:::note
Node in NotReady and Pods in Pending state are expected. Please proceed to the next section to continue with the exercise.
:::