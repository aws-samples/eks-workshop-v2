---
title: "AWS CodePipeline"
sidebar_position: 5
sidebar_custom_props: { "module": true }
description: "AWS CodePipeline Amazon Elastic Kubernetes Service action."
---

:::tip Before you start

Prepare your environment for this section:

```bash timeout=300 wait=30
$ prepare-environment automation/continuousdelivery/codepipeline
```

This command will:

- Create an Amazon ECR repository to store container images
- Create a new AWS CodePipeline for this lab

:::

AWS CodePipeline is a continuous delivery service that enables you to model, visualize, and automate the steps required to release your software. With AWS CodePipeline, you model the full release process for building your code, deploying to pre-production environments, testing your application and releasing it to production. AWS CodePipeline then builds, tests, and deploys your application according to the defined workflow every time there is a code change. You can integrate partner tools and your own custom tools into any stage of the release process to form an end-to-end continuous delivery solution.

Using CodePipeline you can manage source code for your containerized applications, configuration of the clusters, building container images and deployment of these images to environments (EKS clusters) in one workflow.
