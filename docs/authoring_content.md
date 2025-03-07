# EKS Workshop - Authoring Content

This guide outlines how to author content for the workshop, whether adding new content or modifying existing content.

1. [Pre-requisites](#pre-requisites)
1. [Create a work branch](#create-a-work-branch)
1. [Environment setup](#environment-setup)
1. [Planning your content](#planning-your-content)
1. [Writing the markdown](#writing-the-markdown)
1. [Writing the Terraform](#writing-the-terraform)
1. [Cleaning up your lab](#cleaning-up-your-lab)
1. [Testing](#testing)
1. [Tear down AWS resources](#raising-a-pull-request)

## Pre-requisites

The following pre-requisites are necessary to work on the content:

- Access to an AWS account
- Installed locally:
  - Docker
  - `make`
  - `jq`
  - `yq`
  - Node.js + `yarn`
  - `kubectl`

Double-check the version of `yq` installed in your environment. Many package managers will automatically install a version of yq that is incompatible with this workshop as a pre-requisote when installing `jq`. The latest version of `yq` can be downloaded here [https://github.com/mikefarah/yq](https://github.com/mikefarah/yq)

## Create a work branch

The first step is to create a working branch to create the content. There are two ways to do this depending on your access level:

1. (Preferred) Fork the repository, clone it and create a new branch
2. If you have `write` access to this repository you can clone it locally create a new branch directly

Modifications to the workshop will only be accepted via Pull Requests.

## Environment setup

To start developing you'll need to run some initial commands.

First install the dependencies by running the following command in the root of the repository.

```bash
make install
```

Once this is complete you can run the following command to start the development server:

```bash
make serve
```

Note: This command does not return, if you want to stop it use Ctrl+C.

You can then access the content at `http://localhost:3000`.

As you make changes to the Markdown content the site will refresh automatically, you will not need to re-run the command to re-load.

There are some additional things to set up which are not required but will make it more likely to get a PR merged with fewer issues:

- Install pre-commit and run `pre-commit install` so that the pre-commit hooks are run. This will perform basic checks on your changes.

### Creating the infrastructure

When creating your content you will want to test the commands you specify against infrastructure that mirrors what will be used in the actual workshop by learners. This can easily by done locally and with some convenience scripts that have been included.

> [!TIP]
> Why should you use the `make` commands and the associated convenience scripts instead of "doing it yourself"? The various scripts provided are intended to provide an environment consistent with what the end-user of the workshop will use. This is important because the workshop has a number of 3rd party dependencies that are carefully managed with regards to versioning.

Many of the convenience scripts we'll use will make calls to AWS APIs so will need to be able to authenticate. Getting AWS credentials in to a container in a portable way can be a challenge, and there are several options available:

1. Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables in the terminal where you run the `make` commands. It is recommended that these credentials be temporary. These variables will be injected in to the container.
1. If you are developing on an EC2 instance which has an instance profile that provides the necessary IAM permissions then no action is needed as the container will automatically assume the role of the EC2 on which you're authoring your content.

You can then use the following convenience command to create the infrastructure:

```bash
make create-infrastructure
```

Once you're finished with the test environment you can delete all of the infrastructure using the following convenience command:

```bash
make destroy-infrastructure
```

### Simulating the workshop environment

When in the process of creating the content its likely you'll need to be fairly interactive in testing commands etc. During a real workshop users would do this on the Cloud9 IDE, but for our purposes for developing content quickly this is a poor experience because it is designed to refresh content automatically from GitHub. As a result it is recommended to _NOT use the Cloud9 IDE_ created by the Cloud Formation in this repository and instead use the flow below.

The repository provides a mechanism to easily create an interactive shell with access to the EKS cluster created by `make create-infrastructure`. This shell will automatically pick up changes to the content on your local machine and mirrors the Cloud9 used in a real workshop in terms of tools and setup. As such to use this utility you must have already run `make create-infrastructure`.

The shell session created will have AWS credentials injected, so you will immediately be able to use the `aws` CLI and `kubectl` commands with no further configuration.

> [!NOTE]
> If using [finch CLI](https://github.com/runfinch/finch) instead of `docker` CLI you need to set two environment variable `CONTAINER_CLI` or run `make` with the variable set like `CONTAINER_CLI=finch make shell` here how to set the variable in the terminal session for every command.
>
> ```bash
> export CONTAINER_CLI=finch
> ```

Run `make shell`:

```bash
➜  eks-workshop-v2 git:(main) ✗ make shell
bash hack/shell.sh
Generating temporary AWS credentials...
Building container images...
sha256:cd6a00c814bd8fad5fe3bdd47a03cffbb3a6597d233636ed11155137f1506aee
Starting shell in container...
Added new context arn:aws:eks:us-west-2:111111111:cluster/eks-workshop to /root/.kube/config
[root@43267b0ac0c8 /]$ aws eks list-clusters
{
    "clusters": [
        "eksw-env-cluster-eks"
    ]
}
[root@43267b0ac0c8 /]$ kubectl get pod -n kube-system
NAME                                            READY   STATUS    RESTARTS   AGE
aws-load-balancer-controller-858559858b-c4tbx   1/1     Running   0          17h
aws-load-balancer-controller-858559858b-n5rtr   1/1     Running   0          17h
aws-node-gj6sf                                  1/1     Running   0          17h
aws-node-prqff                                  1/1     Running   0          17h
aws-node-sbmx9                                  1/1     Running   0          17h
coredns-657694c6f4-6jbw7                        1/1     Running   0          18h
coredns-657694c6f4-t85xf                        1/1     Running   0          18h
descheduler-5c496c46df-8sr5b                    1/1     Running   0          10h
kube-proxy-nq5qp                                1/1     Running   0          17h
kube-proxy-rpt7c                                1/1     Running   0          17h
kube-proxy-v5zft                                1/1     Running   0          17h
[root@43267b0ac0c8 /]$
```

Depending on your Docker/Finch version, you might need to add a flag to enable [BuildKit builds](https://docs.docker.com/develop/develop-images/build_enhancements/). To do that just run this command `export DOCKER_BUILDKIT=1`, which will set the required env var. After that, you can run again `make shell`.

If your AWS credentials expire you can `exit` and restart the shell, which will not affect your cluster.

## Planning your content

An EKS Workshop lab generally consists of several components:

1. The markdown content in `.md` files that contains the commands to run and explanations for the user
1. Kubernetes manifests that will be referenced in (1) and usually applied to the EKS cluster
1. Terraform configuration to customize the lab environment, for example installing extra components in the EKS cluster or provisioning AWS resources like a DynamoDB table or S3 bucket
1. A shell script which will be used behind the scenes to clean up any changes made to the environment outside of the Terraform in (3) during the course of your lab

Before you begin writing your content it is wise to plan out which of these you will require for your lab. You should refer to existing labs to see examples of patterns that are similar to your scenario.

## Writing the markdown

Once you have a working branch on your local machine you can start writing the workshop content. The Markdown files for the content are all contained in the `website/docs` directory of the repository. This directory is structured using the standard [Docusaurus directory layout](https://docusaurus.io/docs/installation#project-structure). It is recommended to use other modules as guidelines for format and structure.

Please see the [style guide](./style_guide.md) documentation for specific guidance on how to write content so it is consistent across the workshop content.

As you write the content you can use the live local server that we can above to check that it displays correctly.

### What if my content need a new tool installed in the workshop IDE?

The workshop content has various tools and utilities that are necessary to for the learner to complete it, the primary example being `kubectl` along with supporting tools like `jq` and `curl`.

See `lab/Dockerfile` and `lab/scripts/installer.sh` to configure the installed utilities.

## Writing the Terraform

If Terraform is needed it should be created at `./manifests/modules/<yourpath>/.workshop/terraform`. This Terraform will be automatically applied when the user runs `prepare-environment` and destroyed when they move to the next lab.

You can use the directory `templates/lab-manifests/.workshop/terraform` as a starter example. The Terraform is treated as a module and the variables in that directory must match exactly in order to meet the "contract" with the rest of the framework. See `vars.tf` and `outputs.tf`.

### Variables

Certain variables will be provided by the code that invokes your Terraform lab module, you can review these in `vars.tf` mentioned above. These include values such as the EKS cluster name, the cluster version and an "addon context" object which contains values such as the EKS cluster endpoint and OIDC issuer URL.

### Outputs

One optional output is expected, and that is `environment_variables`. This is a map of environment variables that will be added to the users IDE shell. For example:

```hcl
output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value       = {
    MY_ENVIRONMENT_VARIABLE = "abc1234"
  }
}
```

### Terraform best practices

The following are best practices for writing Terraform for a lab:

1. Any AWS infrastructure provisioned should include the EKS cluster name in its name to avoid affecting the automated tests
1. It shouldn't take more than 60 seconds for the Terraform to complete. Remember: the user will be waiting
1. Anything installed (addons, helm charts) should be pinned to explicit versions to unexpected breakages

## Cleaning up your lab

An important part of EKS Workshop is the ability to run labs in any order, and to switch between them with minimal effort. To accomplish this we need to be able to clean up a lab so that the workshop environment is in a known, consistent state before starting the next lab.

The `prepare-environment` command helps orchestrate this clean up by:

1. Resetting the sample application back to its initial state
1. Resetting the EKS Managed Node Groups back to their initial size
1. Destroying all resources created via the Terraform
1. Running a cleanup script provided by the lab

As a workshop author the main unit of work is the cleanup script, which should be created at `./manifests/modules/<yourpath>/.workshop/cleanup.sh`. This should clean up all resources and changes made to the cluster during your lab content **outside of the Terraform configuration**.

Some common examples include:

- Deleting Kubernetes resources applied by the user
- Removing Helm charts installed by the user
- Removing EKS addons installed by the user
- Deleting additional EKS Managed Node groups created by the user

It is also important that all resources be removed conditionally and that errors not be silently swallowed. Failures should bubble up to the user since that means their environment is in an inconsistent state and may need fixed. As a result it would be considered best practice to check that resources exist before deleting them, since this is what allows them to switch labs at any point.

## Testing

All changes should be tested before raising a PR against the repository. There are two ways to test which can be used at different stages of your authoring process.

### Manual testing

Using the `make shell` mechanism outlined above you can manually run through your workshop steps.

### Automated testing

There is an automated testing capability provided with the workshop that allows testing of workshop labs as a unit test suite. This is useful once your content is stable and has been manually tested.

**Your content must be able to be tested in an automated manner. If this is not possible then the content will be rejected due to maintenance burden.**

See this [doc](./automated_tests.md) for more information on automated tests.

## Before your Pull Request

The last step is to ensure that your submission passes all of the linting checks. These are in place to keep the codebase consistent and avoid issues such as basic spelling mistakes.

```bash
make lint
```

If you need to add a new word to the dictionary see the file `.spelling`.

You can resolve prettier formatting problems using `yarn format:fix`.

## Raising a Pull Request

Once your content is completed and is tested appropriately please raise a Pull Request to the `main` branch. This will trigger review processes before the content is merged. All status checks must pass before the PR will be merged, if a check fails then please check the error and attempt to resolve it. If you need assistance then leave a comment on the PR.

Please read the PR template carefully as it will provide guidance on providing a proper title, labels etc.
