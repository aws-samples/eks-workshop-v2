# EKS Workshop - Authoring Content

This guide outlines how to author content for the workshop, whether adding new content or modifying existing content.

## Video tutorial

[<img src="https://user-images.githubusercontent.com/3959052/186980675-a76db290-be21-42ca-af67-547691f94523.png" width="400" link="https://broadcast.amazon.com/videos/591479" />](https://broadcast.amazon.com/videos/591479)

## Pre-requisites

The following pre-requisites are necessary to work on the content:
- Access to an AWS account
- Installed locally:
  - Docker
  - `make`
  - `terraform`
  - `jq`
  - `npm`
  - `kubectl`

## Create a work branch

The first step is to create a working branch to create the content. There are two ways to do this depending on your access level:
1. If you have `write` access to this repository you can clone it locally create a new branch directly
2. Otherwise fork the repository, clone it and create a new branch

Modifications to the workshop will only be accepted via Pull Requests.

## Writing content

Once you have a working branch on your local machine you can start writing the workshop content. The Markdown files for the content are all contained in the `website` directory of the repository. This directory is structured using the standard [Docusaurus directory layout](https://docusaurus.io/docs/installation#project-structure). It is recommended to use other modules as guidelines for format and structure.

Please see the [style guide](./style_guide.md) documentation for specific guidance on how to write content so it is consistent across the workshop content.

As you write the content you can run a live local server that renders the final web site on your local machine. First install the dependencies by running the following command in the root of the repository.

```
make install
```

Then, run the following command to start the development server:

```
make serve
```

Note: This command does not return, if you want to stop it use Ctrl+C.

You can then access the content at `http://localhost:3000`.

As you make changes to the Markdown content the site will refresh automatically, you will not need to re-run the command to re-load.

### What if I need to install a component in the EKS cluster?

Where possible the workshop content aims to avoid having users install components in the EKS cluster using Helm charts, Kubernetes manifests or other means. The goal of the workshop is to teach learners how to use components, not how to install them. As such, the default choice should be to align with the existing patterns for pre-installing all components in the EKS cluster using automation.

Where possible the preference is to use Terraform and EKS Blueprints addons to install dependencies like Helm charts in the EKS cluster. There are a [number of addons](https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/modules/kubernetes-addons) packaged with EKS Blueprints which can be used if your particular component is supported. You can see examples of how to install these addons for workshop content [here](../terraform/modules/cluster/addons.tf).

If the component you require is not already supported by EKS Blueprints you can create a custom addon within this repository. You can see an example of creating a custom addon module [here](../terraform/modules/addons/descheduler/main.tf) and it is installed [here](../terraform/modules/cluster/addons.tf).

#### Helm chart versions

In order to keep up with new versions of Helm charts being published there is an automated mechanism used to monitor all Helm charts used in the workshop content that will raise PRs when new versions are published.

In addition to adding a component to Terraform as outlined in the previous section you must also do the following:
- Edit the file `helm/charts.yaml` and specify the Helm repository, chart name etc.
- Edit the file `terraform/modules/cluster/helm_versions.tf.json` and specify the initial version, note the map name must match the `name` field from `charts.yaml` for your chart.

By default the automated system will look for the latest version of any charts added, but you can control this by using the `constraint` field, which uses the [NPM semantic versioning](https://docs.npmjs.com/about-semantic-versioning) constraint syntax. Please use this sparingly, as any constraints used will require additional maintenance overhead to keep updated. This should mainly be used for charts where:
- The latest chart versions are incompatible with the version of EKS in the content
- The content requires significant changes to bring it inline with a new version

Example constraint in `helm/charts.yaml`:

```
...
- name: aws-load-balancer-controller
  repository: https://aws.github.io/eks-charts
  chart: aws-load-balancer-controller
  constraint: '>=1.4.0 <1.5.0'
...
```

### What if I need to change the AWS infrastructure like VPC, EKS configuration etc?

Any content changes are expected to be accompanied by the any corresponding infrastructure changes in the same Pull Request.

All Terraform configuration resides in the `terraform` directory, and is structured as follows:
- `modules/cluster` contains resources related to VPC, EKS and those used by workloads in EKS (IAM roles)
- `modules/ide` contains resources related to the Cloud9 IDE and its bootstrapping
- `cluster-only` is a small wrapper around `modules/cluster`
- `full` invokes both modules and and connects them together, providing all necessary resources

### What if my content need a new tool installed for the workshop user?

The workshop content has various tools and utilities that are necessary to for the learner to complete it, the primary example being `kubectl` along with supporting tools like `jq` and `curl`.

See `environment/Dockerfile` and `environment/installer.sh` to configure the installed utilities. 

## Testing

All changes should be tested before raising a PR against the repository. There are two ways to test which can be used at different stages of your authoring process.

### Creating the infrastructure

When creating your content you will want to test the commands you specify against infrastructure that mirrors what will be used in the actual workshop by learners. All infrastructure (VPC, EKS cluster etc) is expressed as Terraform configuration in the `terraform` directory.

Ensure that your AWS credentials are set so Terraform is able to authenticate against your IAM account. Terraform will pull credentials from your `~/.aws/credentials` and `~/.aws/config` folders. You can find instructions [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

You can then use the following convenience command to create the infrastructure:

```
make create-infrastructure
```

If you make any changes to the Terraform as part of your workshop content as outlined above you can run this command repeatedly to update the infrastructure incrementally.

Once you're finished with the test environment you can delete all of the infrastructure using the following convenience command:

```
make destroy-infrastructure
```

### Manual testing

When in the process of creating the content its likely you'll need to be fairly interactive in testing commands etc. For this theres a mechanism to easily create an interactive shell with access to the EKS cluster created by the Terraform, as well as including all the necessary tools and utilities without installing them locally.

To use this utility you must:
- Already have created the workshop infrastructure as outlined in the section above
- Have some AWS credentials available in your current shell session (ie. you `aws` CLI must work)

The shell session created will have AWS credentials injected, so you will immediately be able to use the `aws` CLI and `kubectl` commands with no further configuration:

```bash
➜  eks-workshop-v2 git:(main) ✗ make shell
bash hack/shell.sh
Generating temporary AWS credentials...
Building container images...
sha256:cd6a00c814bd8fad5fe3bdd47a03cffbb3a6597d233636ed11155137f1506aee
Starting shell in container...
Added new context arn:aws:eks:us-west-2:111111111:cluster/eksw-env-cluster-eks to /root/.kube/config
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

Depending on your Docker version, you might need to add a flag to enable [BuildKit builds](https://docs.docker.com/develop/develop-images/build_enhancements/). To do that just run this command `export DOCKER_BUILDKIT=1`, which will set the required env var. After that, you can run again `make shell`. 

If your AWS credentials expire you can `exit` and restart the shell, which will not affect your cluster.

### Automated testing

There is also an automated testing capability provided with the workshop that allows testing of the entire workshop flow as a unit test suite. This is useful once your content is stable and has been manually tested.

See this [doc](./automated_tests.md) for more information on automated tests.

## Raise a Pull Request

Once your content is completed and is tested appropriately please raise a Pull Request to the `main` branch. This will trigger review processes before the content is merged.
