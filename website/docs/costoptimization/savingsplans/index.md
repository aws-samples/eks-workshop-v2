---
title: "Savings Plans"
sidebar_position: 10
---

This section is all about saving money on your Amazon EKS workloads!

When your Amazon EKS cluster utilizes [Amazon EC2](https://aws.amazon.com/ec2/pricing/reserved-instances/pricing/) or [AWS Fargate](https://aws.amazon.com/fargate/) instances to run your pods, in general you will be billed at "On-Demand pricing".  That is, you pay for compute capacity by the hour (or by the second) with no long-term commitments.  This works well for many different types of workloads – short-lived, inconsistent, highly variable, etc. - and for customers who don’t want to commit to a specific amount of usage.  For customers that run workloads that have consistent compute requirements, AWS offers options for lower prices compared to On-Demand pricing, in exchange for a specific usage commitment for a one or three-year period.  

Before we get into the specifics, there are a few things to note: 
- There are other places within this workshop that will help demonstrate capabilities for the different compute options available to run your EKS workloads. 
- We are not going to focus selecting Amazon EC2, AWS Fargate, or [Amazon EC2 Spot](https://aws.amazon.com/ec2/spot/) instances to run your workload on Amazon EKS. Let's assume that you've already selected Amazon EC2 and/or AWS Fargate for your compute.  
- We are also not going to focus on operational cost - [this blog](https://aws.amazon.com/blogs/containers/saving-money-pod-at-time-with-eks-fargate-and-aws-compute-savings-plans/) does a great job explaining that.
With those assumptions in mind - let's get started at looking at some of the available discounts available to your Amazon EKS workloads.  

The primary way to achieve a discount is to purchase [Savings Plans](https://aws.amazon.com/savingsplans/) – and we will explore two types of Savings Plans that could apply to your Amazon EKS workloads: Compute Savings Plans and EC2 Instance Savings Plans. In this section we will explain what each type of discount is, how to choose the best fit for your Amazon EKS workload, and then offer some tips as you move forward considering the different options.

