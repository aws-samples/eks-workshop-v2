---
title: "Tips for Using Savings Plans Effectively"
sidebar_position: 30
---

Keep in mind the following tips when evaluating purchasing a Compute or EC2 Instance Savings Plan:
- Remember – this is a commitment.  You will be billed for the entire price of the Savings Plan based on the terms selected. The terms of the commitment can't be changed after purchase. 
- As your usage changes, you can sign up for additional Savings Plans.
- Amazon EKS charges – that is, the charges for having a cluster in your AWS Account - will not be covered by Savings Plans.  Savings Plans cover only the worker nodes - the underlying EC2 instances or AWS Fargate that your pods will run on.
- Recommendations for Savings Plans are aggregated across the entire AWS account, not just your Amazon EKS workload.
- Understand your workload and how it relates to the different Savings Plans options.  For example – if you are using AWS Fargate, the only option that covers that utilization is a Compute Savings Plan.  If you are using [Karpenter](https://karpenter.sh/) to help provision compute capacity – a Compute Savings Plan may be more appropriate as you can specify multiple EC2 instance types for your workload.  If you have static, steady-state workloads then you may be able to take advantage of a larger discount with EC2 Savings Plans.
- You can mix-and-match different types of Savings Plans with different commitment terms.  
- EC2 Reserved Instances are another type of discount vehicle, similar to Savings Plans.  In general, [we recommend Savings Plans over Reserved Instances](https://aws.amazon.com/ec2/pricing/reserved-instances/pricing/) as they offer more flexibility to change as workloads evolve.
- Savings Plans do not provide capacity reservations, but you can allocate On-Demand Capacity Reservation (ODCR) for your needs and your Savings Plans will apply.
- Savings Plans do not apply to spot usage or usage covered by Reserved Instances.
- Savings Plans recommendations require up to 24 hours to reflect your recent Savings Plans purchase, or your recent Savings Plans expiration. Check the Date last updated time to ensure that the recommendation was generated after your recent Savings Plans purchase or expiration.

