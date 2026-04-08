---
title: "Pipeline setup"
sidebar_position: 20
---

Before we run the pipeline, lets configure the cluster so CodePipeline can deploy to it. CodePipeline needs permission to perform operations (`kubectl` or `helm`) on the cluster. For this operation to succeed, we need to add the codepipeline pipeline service role as an access entry to cluster:

```bash
$ aws eks create-access-entry --cluster-name ${EKS_CLUSTER_NAME} \
  --principal-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-codepipeline-role" \
  --type STANDARD
$ aws eks associate-access-policy --cluster-name ${EKS_CLUSTER_NAME} \
  --principal-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-codepipeline-role" \
  --policy-arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" \
  --access-scope '{"type":"cluster"}'
```

Let's explore the CodePipeline that was set up for us, and refer to the CloudFormation that was used to create it.

![Pipeline overview](/docs/automation/continuousdelivery/codepipeline/pipeline.webp)

You can use the button below to navigate to the pipeline in the console:

<ConsoleButton
  url="https://console.aws.amazon.com/codesuite/codepipeline/pipelines/eks-workshop-retail-store-cd/view"
  service="codepipeline"
  label="Open CodePipeline console"
/>

### Source

::yaml{file="manifests/modules/automation/continuousdelivery/codepipeline/.workshop/terraform/pipeline.yaml" zoomPath="Resources.CodePipeline.Properties.Stages.0"}

As mentioned previously this pipeline is configured to retrieve the application source code from an S3 bucket. Here we provide information such as the S3 bucket name and the key where the source file archive is stored.

### Build

::yaml{file="manifests/modules/automation/continuousdelivery/codepipeline/.workshop/terraform/pipeline.yaml" zoomPath="Resources.CodePipeline.Properties.Stages.1"}

This stage is responsible for building the container image by using the [ECRBuildAndPublish action](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-ECRBuildAndPublish.html). It will use the default location of expecting the `Dockerfile` to be in the root of the source repository, then push it to the ECR repository we have configured. It will tag the container image using the [ETag](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#ChecksumTypes) of the source code repository archive in the S3 bucket. This is a hash of the repository file, which in this case we are treating similar to a Git commit ID.

### Deploy

::yaml{file="manifests/modules/automation/continuousdelivery/codepipeline/.workshop/terraform/pipeline.yaml" zoomPath="Resources.CodePipeline.Properties.Stages.2"}

Finally the pipeline uses the [EKSDeploy action](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-EKS.html) to deploy the workload to our EKS cluster. We have configured it to use the Helm chart in the `chart` directory of our source repository.

An important configuration parameter to note is the `EnvironmentVariables` section, which ensures that the `IMAGE_TAG` value is provided such that the container image that was built is used. Notice as in the "Build" stage we are using the ETag value of the repository code archive in S3 so that the new image that was built is used.
