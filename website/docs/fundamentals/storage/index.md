---
title: Storage
sidebar_position: 20
---

[Storage on EKS](https://docs.aws.amazon.com/eks/latest/userguide/storage.html) will provide a high level overview on how to integrate two AWS Storage services with your EKS cluster.

Before we dive into the implementatio, below is a summary of the two AWS storage services we will utilize and integrat with EKS:



* [Amazon Elastic Block Store](https://aws.amazon.com/ebs/) (supports EC2 only): a block storage service that provides direct access from EC2 instances and containers to a dedicated storage volume designed for both throughput and transaction-intensive workloads at any scale.
* [Amazon Elastic File System](https://aws.amazon.com/efs/) (supports Fargate and EC2): a fully managed, scalable, and elastic file system well suited for big data analytics, web serving and content management, application development and testing, media and entertainment workflows, database backups, and container storage. EFS stores your data redundantly across multiple Availability Zones (AZ) and offers low latency access from Kubernetes pods irrespective of the AZ in which they are running.
* [FSx for Lustre](https://aws.amazon.com/fsx/lustre/) (supports EC2 only): a fully managed, high-performance file system optimized for workloads such as machine learning, high-performance computing, video processing, financial modeling, electronic design automation, and analytics. With FSx for Lustre, you can quickly create a high-performance file system linked to your S3 data repository and transparently access S3 objects as files. **FSx will be discussed on future modules of this workshop**

On the following steps, we will first integrate a Amazon EBS volume to be consumed by our MySQL database from the catalog microservice utilizing a statefulset object on Kubernetes. 
After that we'll integrate our component microservice filesystem to use the Amazon EFS shared file system, providing scalability, resiliency and more control over the files from our microservice. 