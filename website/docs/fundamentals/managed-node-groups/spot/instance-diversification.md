---
title: "Instance type diversification"
sidebar_position: 10
---

[Amazon EC2 Spot Instances](https://aws.amazon.com/ec2/spot/) offer spare compute capacity available in the AWS Cloud at steep discounts compared to On-Demand prices. EC2 can interrupt Spot Instances with two minutes of notification when EC2 needs the capacity back. You can use Spot Instances for various fault-tolerant and flexible applications. Some examples are analytics, containerized workloads, high-performance computing (HPC), stateless web servers, rendering, CI/CD, and other test and development workloads.

One of the best practices to successfully adopt Spot Instances is to implement **Spot Instance diversification** as part of your configuration. Spot Instance diversification helps to procure capacity from multiple Spot Instance pools, both for scaling up and for replacing Spot Instances that may receive a Spot Instance termination notification. A Spot Instance pool is a set of unused EC2 instances with the same Instance type, operating system and Availability Zone (for example, `m5.large` on Red Hat Enterprise Linux in `us-east-1a`).

### Cluster Autoscaler with Spot Instance Diversification

Cluster Autoscaler is a tool that automatically adjusts the size of the Kubernetes cluster when there are pods that fail to run in the cluster due to insufficient resources (Scale Out) or there are nodes in the cluster that have been underutilized for a period of time (Scale In).

:::tip
When using Spot Instances with [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) there are a few things that [should be considered](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md). One key consideration is, each Auto Scaling group should be composed of instance types that provide approximately equal capacity. Cluster Autoscaler will attempt to determine the CPU, memory, and GPU resources provided by an Auto Scaling Group based on first override provided in an ASG's Mixed Instances Policy. If any such overrides are found, only the first instance type found will be used. See [Using Mixed Instances Policies and Spot Instances](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#Using-Mixed-Instances-Policies-and-Spot-Instances) for details.
:::

When applying Spot diversification best practices to EKS and K8s clusters while using Cluster Autoscaler to dynamically scale capacity, we must implement diversification in a way that adheres to Cluster Autoscaler expected operational mode.

We can diversify Spot Instance pools using two strategies:

- By creating multiple node groups, each of different sizes. For example, a node group of size 4 vCPUs and 16GB RAM, and another node group of 8 vCPUs and 32GB RAM.
- By Implementing instance diversification within the node groups, by selecting a mix of instance types and families from different Spot Instance pools that meet the same vCPUs and memory criteria.

In this workshop we will assume that our cluster node groups should be provisioned with instance types that have 2 vCPU and 4GiB of memory.

We will use **[amazon-ec2-instance-selector](https://github.com/aws/amazon-ec2-instance-selector)** to help us select the relevant instance
types and families with sufficient number of vCPUs and RAM.

There are over 350 different instance types available on EC2 which can make the process of selecting appropriate instance types difficult. To make it easier, `amazon-ec2-instance-selector`, a CLI tool, helps you select compatible instance types for your application to run on. The command line interface can be passed resource criteria like cpus, memory, network performance, and much more and then return the available, matching instance types.

The CLI tool has been pre-installed in your IDE:

```bash
$ ec2-instance-selector --version
```

Now that you have ec2-instance-selector installed, you can run `ec2-instance-selector --help` to understand how you could use it for selecting instances that match your workload requirements. For the purpose of this workshop we need to first get a group of instances that meet our target of 2 vCPUs and 4 GB of RAM.

Run the following command to get the list of instances.

```bash
$ ec2-instance-selector --vcpus 2 --memory 4 --gpus 0 --current-generation \
  -a x86_64 --deny-list 't.*' --output table-wide
Instance Type   VCPUs   Mem (GiB)  Hypervisor  Current Gen  Hibernation Support  CPU Arch  Network Performance  ENIs    GPUs    GPU Mem (GiB)  GPU Info  On-Demand Price/Hr  Spot Price/Hr
-------------   -----   ---------  ----------  -----------  -------------------  --------  -------------------  ----    ----    -------------  --------  ------------------  -------------
c5.large        2       4          nitro       true         true                 x86_64    Up to 10 Gigabit     3       0       0              none      $0.085              $0.0344
c5a.large       2       4          nitro       true         false                x86_64    Up to 10 Gigabit     3       0       0              none      $0.077              $0.0275
c5ad.large      2       4          nitro       true         false                x86_64    Up to 10 Gigabit     3       0       0              none      $0.086              $0.0403
c5d.large       2       4          nitro       true         true                 x86_64    Up to 10 Gigabit     3       0       0              none      $0.096              $0.0468
c6a.large       2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.0765             $0.0313
c6i.large       2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.085              $0.0351
c6id.large      2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.1008             $0.0472
c6in.large      2       4          nitro       true         true                 x86_64    Up to 25 Gigabit     3       0       0              none      $0.1134             $0.0396
c7a.large       2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.10264            $0.0338
c7i-flex.large  2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.08479            $0.0419
c7i.large       2       4          nitro       true         true                 x86_64    Up to 12.5 Gigabit   3       0       0              none      $0.08925            $0.031
```

We'll use these instances when we define our node group in the next section.

Internally `ec2-instance-selector` is making calls to the [DescribeInstanceTypes](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstanceTypes.html) for the specific region and filtering the instances based on the criteria selected in the command line, in our case we filtered for instances that meet the following criteria:

- Instances with no GPUs
- of x86_64 Architecture (no ARM instances like A1 or m6g instances for example)
- Instances that have 2 vCPUs and 4 GB of RAM
- Instances of current generation (4th gen onwards)
- Instances that don’t meet the regular expression `t.*` to filter out burstable instance types

:::tip
Your workload may have other constraints that you should consider when selecting instance types. For example. **t2** and **t3** instance types are [burstable instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html) and might not be appropriate for CPU bound workloads that require CPU execution determinism. Instances such as m5**a** are [AMD Instances](https://aws.amazon.com/ec2/amd/), if your workload is sensitive to numerical differences (i.e: financial risk calculations, industrial simulations) mixing these instance types might not be appropriate.
:::
