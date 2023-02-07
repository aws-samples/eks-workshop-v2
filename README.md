# Amazon Elastic Kubernetes Service Workshop

![Tests](https://github.com/aws-samples/eks-workshop-v2/actions/workflows/ci.yaml/badge.svg?branch=main)

Welcome to the content repository for the Amazon Elastic Kubernetes Services workshop.

## Navigating the repository

The top level repository can be split is to several areas.

### Site content

The workshop content itself is a `docusaurus` site. All workshop content is written using Markdown and can be found in `website`.

### Contributing content

To learn how to author content on this repository, read docs/[authoring_content.md](docs/authoring_content.md).

### Workshop infrastructure

The infrastructure required to run the workshop content (EKS cluster configuration, VPC networking, components like Helm charts) are defined as Terraform infrastructure-as-code configuration in the `terraform` directory.

### Learner environment

There are several tools that are required to run the workshop such as `kubectl` that need to be installed for a participant to complete the workshop content. This "learner environment" can be setup automatically using the scripts and other artifacts in the `environment` directory. This includes scripts to install all the pre-requisite tools, as well as container images to easily re-create a consistent environment.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.
