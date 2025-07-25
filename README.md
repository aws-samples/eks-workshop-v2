<!-- markdownlint-disable MD041 -->
<div align="center">
  <a href="https://eksworkshop.com" target="_blank" rel="noopener noreferrer">
    <picture>
      <img width="160" src="docs/images/eks.png" alt="Amazon Elastic Kubernetes Service logo">
    </picture>
  </a>
  
  <br/>

  <div align="center">

[![Stars](https://img.shields.io/github/stars/aws-samples/eks-workshop-v2)](LICENSE)
[![License](https://img.shields.io/github/license/aws-samples/eks-workshop-v2)](LICENSE)

  </div>

  <strong>
  <h2>Amazon Elastic Kubernetes Service Workshop</h2>
  </strong>
</div>

Welcome to the repository for the [Amazon Elastic Kubernetes Services workshop](https://eksworkshop.com). This contains the source for the website content as well as the accompanying infrastructure-as-code to set up a workshop lab environment in your AWS account. Please review the [Introduction](https://www.eksworkshop.com/docs/introduction/) chapter of the workshop for more details.

The preview version of the site built from the `main` branch is available [here](https://preview.eksworkshop.com/).

## Introduction

The Amazon EKS Workshop is built to help users learn about Amazon EKS features and integrations with popular open-source projects. The workshop is abstracted into high-level learning modules, including Networking, Security, DevOps Automation, and more. These are further broken down into standalone labs focusing on a particular feature, tool, or use-case. To ensure a consistent and predictable learning experience, the Amazon EKS Workshop closely adheres to the following tenets:

**Tenets**:

- **Modular**: The workshop is made up of standalone modules that can be individually completed, allowing you to start at any module and easily switch between them.
- **Consistent sample app**: The workshop uses the same sample retail store application across all modules: AWS Containers Retail Sample.
- **Amazon EKS-focused**: Although the workshop covers some Kubernetes basics, it primarily focuses on familiarizing the user with concepts directly related to Amazon EKS.
- **Continuously tested**: We automatically test the infrastructure provisioning and CLI steps in the workshop, allowing us to keep the workshop updated and tracking the latest versions of Amazon EKS.

## Navigating the repository

The top level repository can be split is to several areas.

### Site content

The workshop content itself is a `docusaurus` site. All workshop content is written using Markdown and can be found in `website`.

### Contributing content

To learn how to author content on this repository, read [CONTRIBUTING.md](CONTRIBUTING.md) and the [authoring content guide](docs/authoring_content.md).

### Workshop infrastructure

The infrastructure required to run the workshop content (EKS cluster configuration, VPC networking, components like Helm charts) are defined as Terraform infrastructure-as-code configuration in the `terraform` directory.

### Learner environment

There are several tools that are required to run the workshop such as `kubectl` that need to be installed for a participant to complete the workshop content. This "learner environment" can be setup automatically using the scripts and other artifacts in the `environment` directory. This includes scripts to install all the pre-requisite tools, as well as container images to easily re-create a consistent environment.

## Community

### Governance

- Steering Committee: [governance/steering.md](governance/steering.md)
- Governance model: [governance/model.md](governance/model.md)
- Tenets: [governance/tenets.md](governance/tenets.md)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.
