---
title: AMI updates
sidebar_position: 60
---

Amazon EKS gives the end users the flexibility to deploy nodes either with Amazon Linux AMI's or build your own custom AMI's. 

Below are the list of the supported Node OS:

* [Amazon Linux Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
* [Ubuntu Linux](https://docs.aws.amazon.com/eks/latest/userguide/eks-partner-amis.html), 
* [Bottlerocket](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html)
* [Windows](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-windows-ami.html).


**Note:** Starting with kubernetes version 1.24, Amazon EKS will end the support for `Dockershim`. The only runtime available would be
`containerd`.

To get more details on the latest available EKS optimized AMI's 

