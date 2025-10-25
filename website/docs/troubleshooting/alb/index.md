---
title: "ALB Controller"
chapter: true
sidebar_position: 40
sidebar_custom_props: { "module": true }
---

::required-time

In this lab, we'll explore common issues that can occur when working with Amazon EKS and learn effective troubleshooting techniques. We'll work through real-world scenarios focusing on the AWS Load Balancer Controller and service connectivity problems. If you'd like to learn more about how a Load balancer controller work, check out the [Fundamentals module](/docs/fundamentals/) or [AWS LB Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) official documentation for more information.

:::tip Before you start
Prepare your environment for this section:

```bash timeout=600 wait=10
$ prepare-environment troubleshooting/alb
```
You can view the Terraform that applies these changes [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/troubleshooting/alb/.workshop/terraform).
:::
:::info

The preparation of the lab might take a couple of minutes and it will make the following changes to your lab environment:


- Deploy a sample UI application
- Configure an ingress resource
- Set up initial AWS Load Balancer Controller configuration (with deliberate issues for troubleshooting)
- Create necessary IAM roles and policies

:::

## Environment Setup Details

The prepare-environment script has created several resources with specific issues that we'll troubleshoot:

- A UI application deployment in the ui namespace
- An ingress resource configured to use the AWS Load Balancer Controller
- IAM roles and policies (with intentional misconfigurations)
- Kubernetes service resources

These components have been configured with common real-world issues that we'll identify and fix throughout this module.

## What We'll Cover

We'll troubleshoot several issues including:

- Missing or incorrect subnet tags preventing ALB creation
- IAM permission issues blocking the Load Balancer Controller
- Service selector misconfigurations
- Ingress backend service problems

## Prerequisites

Before proceeding, ensure you have:

- Access to the EKS cluster
- Proper AWS CLI configuration
- kubectl installed and configured
  -Basic understanding of Kubernetes networking concepts

## Tools We'll Use

Throughout this module, we'll use these troubleshooting tools:

- kubectl commands for Kubernetes resource inspection
- AWS CLI for checking AWS resource states
- CloudWatch Logs for controller diagnostics
- AWS IAM tools for permission verification

:::tip Before you proceed
After a couple minutes from running the prepare-environment script, verify the service and ingress is up and running.

```bash
$ kubectl get svc -n ui
NAME   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
ui     ClusterIP   172.20.224.112   <none>        80/TCP    12d
```

```bash
$ kubectl get ingress -n ui
NAME   CLASS   HOSTS   ADDRESS   PORTS   AGE
ui     alb     *                 80      11m

```

Let's verify the load balancer was indeed not created:

```bash
$ aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]'
[]
```

:::
Let's begin by investigating why our Application Load Balancer isn't being created!
