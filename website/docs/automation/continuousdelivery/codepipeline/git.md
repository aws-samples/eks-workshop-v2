---
title: "Git repository"
sidebar_position: 10
---

:::note
CodePipeline supports GitHub, GitLab, and Bitbucket through AWS CodeConnections as Git-based sources. In a real application, you should use these sources. However for simplicity in this lab we will use S3 as the source repository.
:::

This module uses S3 as a source action, and we'll use the [git-remote-s3](https://github.com/awslabs/git-remote-s3?tab=readme-ov-file#repo-as-s3-source-for-aws-codepipeline) library to populate that bucket through `git` in our web IDE.

Our repository will consist of:

1. A Dockerfile to create a custom UI container image
2. A Helm chart to deploy the component
3. A `values.yaml` file to override the image that is deployed

```text
.
├── chart/
|   ├── templates/
|   ├── Chart.yaml
│   └── values.yaml
|── values.yaml
└── Dockerfile
```

First let's set up Git:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
```

Then copy the various files to a directory we'll use for our Git repository:

```bash timeout=120
$ mkdir -p ~/environment/codepipeline/chart
$ git -C ~/environment/codepipeline init -b main
$ git -C ~/environment/codepipeline remote add \
  origin s3+zip://${EKS_CLUSTER_NAME}-${AWS_ACCOUNT_ID}-retail-store-sample-ui/my-repo
$ cp -R ~/environment/eks-workshop/modules/automation/continuousdelivery/codepipeline/repo/* \
  ~/environment/codepipeline
$ helm pull oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart:0.8.5 \
  -d /tmp
$ tar zxf /tmp/retail-store-sample-ui-chart-0.8.5.tgz \
  -C ~/environment/codepipeline/chart --strip-components=1
```

For now we won't push the files as we don't want to trigger our pipeline yet.
