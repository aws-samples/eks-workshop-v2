---
title: "Savings Plans"
sidebar_position: 10
---

This section is all about saving money on your Amazon EKS workloads!

When your Amazon EKS cluster utilizes [Amazon EC2](https://aws.amazon.com/ec2/pricing/reserved-instances/pricing/) or [AWS Fargate](https://aws.amazon.com/fargate/) instances to run your workloads, in general you will be billed at "On-Demand pricing". That is, you pay for compute capacity by the hour (or by the second) with no long-term commitments.  This works well for many different types of workloads – short-lived, inconsistent, highly variable, etc., and for customers who don’t want to commit to a specific amount of usage.  For customers that run workloads that have consistent compute requirements, AWS offers options for discounts compared to On-Demand pricing.  The primary way to achieve a discount is to purchase [Savings Plans](https://aws.amazon.com/savingsplans/) – and we'll explore two types of Savings Plans that could apply to your Amazon EKS workloads: Compute Savings Plans and EC2 Instance Savings Plans.

## What are Savings Plans?
Savings Plans offer a flexible pricing model that provides savings on AWS usage. Relative to Amazon EKS workloads, there are two types of Savings Plans that apply – Compute Savings Plans and EC2 Instance Savings Plans.  While both are similar in that they offer a discount over On-Demand pricing, it’s important to understand the difference before making a commitment to purchase.

### Compute Savings Plans
Compute Savings Plans provide the most flexibility and prices that are up to 66% off of On-Demand rates. These plans automatically apply to your EC2 instance usage, regardless of instance family, instance size, Region, operating system, or tenancy. Compute Savings Plans apply to usage across Amazon EC2, AWS Lambda, and AWS Fargate. With Compute Savings Plans, you can move a workload from one instance family to another, shift your usage between AWS Regions, or migrate your application from Amazon EC2 to Amazon EKS using AWS Fargate at any time. You can continue to benefit from the lower prices provided by Compute Savings Plans as you make these changes.

### EC2 Instance Savings Plans
EC2 Instance Savings Plans provide savings up to 72% off On-Demand, in exchange for a commitment to a specific instance family in a chosen AWS Region. These plans automatically apply to usage regardless of size, OS, and tenancy within the specified family within a Region. With an EC2 Instance Savings Plan, you can change your instance size within the instance family or the operating system, or move from Dedicated tenancy to Default and continue to receive the discounted rate provided by your EC2 Instance Savings Plan.

### Payment Terms
The payment options available are common to both Compute and EC2 Instance Savings Plans - you can chose to pay All Upfront, Partial Upfront, or No Upfront:
- **All Upfront** - Pay for the entire Savings Plans term with one upfront payment. This option provides the largest discount compared to On-Demand Instance pricing.
- **Partial Upfront** - Make a low upfront payment, and the hourly rate is discounted for the duration of the Savings Plan term.
- **No Upfront** - There is no upfront payment required at time of purchase.

### Comparing Compute and EC2 Instance Savings Plans
The Savings Plans [documentation](https://docs.aws.amazon.com/savingsplans/latest/userguide/what-is-savings-plans.html) contains a table comparing the properties of Savings Plans and EC2 Instance Savings Plans:

|                                                                         |     Compute Savings Plans    |     EC2 Instance Savings Plans    |
|-------------------------------------------------------------------------|------------------------------|-----------------------------------|
|     Savings over On-Demand                                              |     Up to 66%                |     Up to 72%                     |
|     Lower price in exchange for monetary commitment                     |     ✓                        |     ✓                             |
|     Automatically applies pricing to any instance family                |     ✓                        |     —                             |
|     Automatically applies pricing to any instance size                  |     ✓                        |     ✓                             |
|     Automatically applies pricing to any Tenancy or OS                  |     ✓                        |     ✓                             |
|     Automatically applies to Amazon ECS and Amazon EKS using Fargate    |     ✓                        |     —                             |
|     Automatically applies to Lambda                                     |     ✓                        |     —                             |
|     Automatically applies pricing across AWS Regions                    |     ✓                        |     —                             |
|     Term length options of 1 or 3 years                                 |     ✓                        |     ✓                             |

The table above illustrates that Compute Savings Plan can be applied universally across all instance types across al regions, as well as applying to AWS Fargate and Lambda.  EC2 Instance Plans, while potentially offering a larger discount than Compute Savings Plans, have restrictions on what they apply to.

## Tips for Using Savings Plans Effectively
Keep in mind the following tips when evaluating purchasing Compute or EC2 Instance Savings Plans:
- Savings Plans are a commitment.  You will be billed for the entire price of the Savings Plan based on the terms selected. 
- The terms of the commitment can't be changed after purchase. However, as your usage changes, you can sign up for additional Savings Plans, and you can mix-and-match different types of Savings Plans with different commitment terms.
- Savings Plans do not apply to Amazon EKS service charge (i.e. the control plane). Savings Plans can cover your worker nodes - the underlying EC2 instances or AWS Fargate that your workloads run on.
- Recommendations for Savings Plans are aggregated across the entire AWS account, not just your Amazon EKS workload.
- Understand your workload and how it relates to the different Savings Plans options.  For example, if you're using AWS Fargate, the only option that covers that utilization is a Compute Savings Plan.  If you're using [Karpenter](https://karpenter.sh/) to help provision compute capacity – a Compute Savings Plan may be more appropriate as you can specify multiple EC2 instance types for your workload.  If you have static, steady-state workloads then you may be able to take advantage of a larger discount with EC2 Savings Plans.
- EC2 Reserved Instances are another type of discount available, similar to Savings Plans.  In general, [we recommend Savings Plans over Reserved Instances](https://aws.amazon.com/ec2/pricing/reserved-instances/pricing/) as they offer more flexibility to change as workloads evolve.
- Savings Plans do not apply to spot usage or usage covered by Reserved Instances.

## Additional Reading
Check out the following links for more reading on Savings Plans:
- [AWS Savings Plans Product Page](https://aws.amazon.com/savingsplans/)
- [AWS Savings Plans User Guide](https:/docs.aws.amazon.com/savingsplans/latest/userguide/what-is-savings-plans.html)
