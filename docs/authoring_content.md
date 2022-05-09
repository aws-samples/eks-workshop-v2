# EKS Workshop - Authoring Content

This guide outlines how to author content for the workshop, whether adding new content or modifying existing content.

## Pre-requisites

The following pre-requisites are necessary to work on the content:
- Access to an AWS account
- Installed locally:
  - Docker
  - `make`
  - `hugo`
  - `terraform`
  - `jq`

## Fork & clone the repository

The first step is to fork the repository and then clone it to your local machine. Modifications to the workshop will only be accepted via Pull Requests from forks of the repository.

## Run preview site

You can run a live local server that renders the final content on your local machine by running the following command in the root of the repository:

```
make serve
```

Note: This command does not return, if you want to stop it use Ctrl+C.

You can then access the content at `http://localhost:1313`.

As you make changes to the Markdown content the site will refresh automatically, you will not need to re-run the command to re-load.

## Content changes

The Markdown files for the content are all contained in the `site/content` directory of the repository. This directory is structured using the standard [Hugo directory layout](https://gohugo.io/content-management/organization/).

## Infrastructure changes

Depending on the nature of the content changes it may be necessary to make modifications to this infrastructure configuration. Examples include:
- A change to the EKS cluster such as adding a new node group or installing an addon component
- Altering some supporting infrastructure such as VPC networking or IAM permissions
- Modifications to the Cloud9 environment such as instance type, available storage etc.

Any content changes are expected to be accompanied by the any corresponding infrastructure changes in the same Pull Request.

All Terraform configuration resides in the `terraform` directory, and is structured as follows:
- `modules/cluster` contains resources related to VPC, EKS and those used by workloads in EKS (IAM roles)
- `modules/ide` contains resources related to the Cloud9 IDE and its bootstrapping
- `cluster-only` is a small wrapper around `modules/cluster`
- `full` invokes both modules and and connects them together, providing all necessary resources

## Dependency changes

The workshop content has various dependencies that are necessary to run it in addition to the Terraform infrastructure. These include:
- Binaries like `kubectl`, `helm` etc. that are used by learners throughout the content
- Helm charts which are used to install components such as AWS Load Balancer Controller etc.

These have specific mechanisms in place to help automate tracking dependency updates.

### Helm charts

Helm charts are primarily installed using Terraform, but the versions which are installed are maintained by an automated script that runs daily to check for new versions of these charts.

To add a new Helm chart edit the file `helm/charts.yaml` and follow the existing content as an example. 

By default the automated system will look for the latest version of any charts added, but you can control this by using the `constraint` field, which uses the [NPM semantic versioning](https://docs.npmjs.com/about-semantic-versioning) constraint syntax. Please use this sparingly, as any constraints used will require additional maintenance overhead to keep updated. This should mainly be used for charts where:
- The latest chart versions are incompatible with the version of EKS in the content
- The content requires significant changes to bring it inline with a new version

This changed in this YAML file will be reflected in the Terraform variables file `terraform/modules/cluster/helm_versions.tf.json`.

## Testing

All changes should be tested before raising a PR against the repository. This can be done in any manner which authoring the content but if necessary the automated test procedure should be used.

This should be run if:
- Any `code` blocks have been modified that the user will execute
- Any changes have been made to the Terraform infrastructure

Before running the tests you should:
- Have credentials available in the current shell session (either AWS CLI logged in, environment variables set etc.)
- Identify an IAM role in your AWS account which can be used to run the test suite

Run this command from the root of the repository:

```
ASSUME_ROLE=arn:aws:iam::<accountId>:role/<roleName> make e2e-test
```

If you want to skip creating the infrastructure and just run the tests on an existing cluster you can run:

```
ASSUME_ROLE=arn:aws:iam::<accountId>:role/<roleName> make test
```