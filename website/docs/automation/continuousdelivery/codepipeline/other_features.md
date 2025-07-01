---
title: "Features of CodePipeline"
sidebar_position: 40
---

### Other features of EKS action in CodePipeline

1. **Private cluster support**: Users can configure clusters with private-only access in the CodePipeline EKS action. By default, CodePipeline uses Subnets and Security groups as configured in the cluster. However, you can override them by specifying them in the action configuration.
2. **Helm**: In addition to `kubectl`, CodePipeline EKS action allows users to configure the EKS action with `helm` charts. The action also accepts input in .tgz format. So, if you have helm charts in .tgz format in an S3 bucket, you can use that directly by adding the S3 bucket/key as a separate source action, without zipping them.

### Other CD features of CodePipeline that can be used with EKS action

1. **Dynamic variables**: CodePipeline allows users to change the input to an action at runtime using variables. CodePipeline supports action and pipeline level variables. Action variable values are produced at runtime by an action (as seen in this module). Pipeline variables, on the other hand, are provided by the user before starting the pipeline execution.
2. **Release orchestration control**: CodePipeline allows release orchestration operations to users. These operations include retrying, stopping, blocking and rolling-back a pipeline run.
3. **Release safety**: CodePipeline adds release safety to deployments by allowing users to automate release operations. Users can achieve this by adding conditions in their stages.

   i. **Entry Gates**: Users can add entry criteria (a stage condition) to block/skip deployments if the entry criteria is met. You can add a time-window to your EKS action stage to time the deployments during specific times of the day/week. Similarly, you can add CloudWatch alarms to allow deployments only when your deployment environments are healthy. You can also skip deployments if a certain condition is met, such as when a change-set is intended for certain environments. [Release safety blog](https://aws.amazon.com/blogs/devops/enhance-release-control-with-aws-codepipeline-stage-level-conditions/)

   ii. **Exit gates**: Users can add exit criteria (a stage condition) to fail, retry, or roll back deployments if the criteria is met. You can add CloudWatch alarms and roll back your deployment if the CloudWatch alarm is red. You can auto-retry if the deployment environment is flaky. [Auto-rollbacks blog](https://aws.amazon.com/blogs/devops/de-risk-releases-with-aws-codepipeline-rollbacks/)

4. **Manual Approval** In addition to automating the orchestration of pipeline runs, CodePipeline allows you to configure your release process to be approval driven. The manual approval action allows you to inspect and approve/reject application changes.
