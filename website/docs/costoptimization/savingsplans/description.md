---
title: "What are Savings Plans?"
sidebar_position: 30
---

Savings Plans offer a flexible pricing model that provides savings on AWS usage. In certain instances, you can save up to 72% on your AWS compute workloads. Savings Plans provide savings beyond On-Demand rates in exchange for a commitment of using a specified amount of compute (measured per hour) for a one or three year period. Relative to Amazon EKS, there are two types of Savings Plans that apply to worker nodes – Compute Savings Plans and EC2 Instance Savings Plans.

Note that there is another type Savings Plans offered - SageMaker Savings Plans – however it does not apply directly to Amazon EKS.  For more information, check [here](https://aws.amazon.com/savingsplans/ml-pricing/).

You can choose between three payment options when you purchase both Compute and EC2 Instance Savings Plans. With the All Upfront option, you pay for the entire Savings Plans term with one upfront payment. This option provides you with the largest discount compared to On-Demand Instance pricing. With the Partial Upfront option, you make a low upfront payment and are then charged a discounted hourly rate for the duration of the Savings Plan term. The No Upfront option does not require any upfront payment and provides a discounted hourly rate for the duration of the term.

## Compute Savings Plans
Compute Savings Plans provide the most flexibility and prices that are up to 66% off of On-Demand rates. These plans automatically apply to your EC2 instance usage, regardless of instance family, instance size, Region, operating system, or tenancy. Compute Savings Plans apply to usage across Amazon EC2, AWS Lambda, and AWS Fargate. With Compute Savings Plans, you can move a workload from one instance family to another, shift your usage between AWS Regions, or migrate your application from Amazon EC2 to Amazon EKS using AWS Fargate at any time. You can continue to benefit from the lower prices provided by Compute Savings Plans as you make these changes.

## EC2 Instance Savings Plans
EC2 Instance Savings Plans provide savings up to 72% off On-Demand, in exchange for a commitment to a specific instance family in a chosen AWS Region. These plans automatically apply to usage regardless of size, OS, and tenancy within the specified family within a Region. With an EC2 Instance Savings Plan, you can change your instance size within the instance family or the operating system, or move from Dedicated tenancy to Default and continue to receive the discounted rate provided by your EC2 Instance Savings Plan.

## Comparing Compute and EC2 Instance Savings Plans
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

The key takeaway from this table is as follows:  Compute Savings Plan can be applied universally across all instance types across al regions, as well as applying to AWS Fargate and Lambda.  EC2 Instance Plans, while potentially offering a larger discount than Compute Savings Plans, come with more restrictions on what they apply to.


