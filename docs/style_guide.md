# EKS Workshop - Style Guide

This document provides a style guide that should be used when creating or modifying content for the workshop in order to maintain a consistent experience throughout the content.

## Scripts/Commands

This section provides guidelines related to the commands and scripts learners are instructed to use during the workshop content.

### Command blocks

All commands to the executed by the user should be contained within a Markdown `code` block specifying the language as `bash`. This is being used by tools like automated testing so must be consistent.

For example instead of this:

````
```
$ kubectl get pods
```
````

It is preferable to use this:

````
```bash
$ kubectl get pods
```
````

Enter the command exactly as it should be run by the learner, prefixed with `$ `.

For example instead of this:

````
```bash
[root@b32a35acd6b6 /]$ kubectl get pods
```
````

You should do this:

````
```bash
$ kubectl get pods
```
````

Expected output from a command the learner runs can be displayed under the command, do not prefix it with anything:

````
Please run this command:

```bash
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS      AGE
aws-node-1z3ng             1/1     Running   1 (16h ago)   21h
```
````

### Asynchronous commands

The nature of Kubernetes as a declarative system means that often commands can be run that alter the state of the cluster and return immediately while the state is reconciled. Examples of this include `kubectl apply` and `helm install`. This can cause a number of issues:

1. Learners may try to immediately interact with the resources being created or modified, which can cause "race conditions"
2. Content can be made more complex by instructing the learner to "wait" or repeatedly run commands to check the state of the resources
3. No immediate feedback in the case of errors

As much as possible commands that provide some sort of "wait" function should leverage it, or be accompanied by a command that waits for an explicit condition.

For example instead of this:

```bash
$ kubectl apply -f manifest.yaml
[...]
```

It is preferable to use this:

```bash
$ kubectl apply -f manifest.yaml
[...]
$ kubectl wait --for=condition=available --timeout=60s deployment/example
```

Similarly with `helm` use `--wait`:

```bash
$ helm upgrade --install --namespace karpenter \
  karpenter karpenter/karpenter \
  --wait
```

### Referencing Pods

When running `kubectl` commands that reference Pods care should be taken to ensure that it is done in a way that will work in situations where the Pod name might be variable or generated, for example Pods that are created by a `Deployment`.

For example instead of this:

```bash
$ kubectl describe pod example-abc123
```

It is preferable to use this:

```bash
$ kubectl describe pod deployment/example
```

Alternatively, use labels and selectors:

```bash
$ kubectl get pods --selector=app=example
```

### Use of `kubectl exec`

During the course of modules its often necessary to use the `kubectl exec` command to open a shell in a running container. Where possible the content should avoid opening persistent shell sessions to containers and instead bias towards executing discrete commands.

For example, instead of this:

```bash
$ kubectl exec -it deployment/example -- bash
[root@b32a35acd6b6 /]$ curl localhost:8080
Hello!
[root@b32a35acd6b6 /]$ exit
$ 
```

It is preferable to use this:

```bash
$ kubectl exec -it deployment/example -- curl localhost:8080
Hello!
$
```

### Avoid use of multiple windows/shells

Sometimes it is tempting to execute a long-running command in one window and instruct the learner to open a new shell window to run another command while that is happening. Examples of this include generating load while watching a Deployment scale horizontally. Use of this approach should be avoided as much as possible for a number of reasons:

1. It can be confusing for the learner to switch between multiple windows
2. Contextual information like environment variables can get lost in new windows
3. It is more difficult to test


### Referencing external manifests or components

If something like a manifest hosted externally is to be referenced by content it should be pinned as explicitly as possible to prevent changes to these files causing uncontrolled changes to the content experience, or worse breaking it entirely.

When fetching a manifest from GitHub do not refer to `master` or `main` and instead refer to either a tag or specific commit.

For example, instead of this:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml
```

It is preferable to use this:

```
$ kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/v0.0.86/stable/aws-load-balancer-controller/crds/crds.yaml
```

Notice we changed from referring to `master` to referring to the tag `v0.0.86`.

### Referencing existing AWS infrastructure in content

It is common in workshop content to reference various AWS infrastructure that has been build by the Terraform configuration provided. Some examples of this include:
- Getting the cluster name to reference in a Kubernetes manifest
- Modifying EKS managed node group configuration by name

Names of these resources should NOT be hardcoded in content, as even though the default name is predictable the content is designed in a way to make it possible to have multiple instances of the workshop infrastructure in a single AWS account and region.

The recommendation is to use the EKS cluster name where possible, and this is provided by default in the learning environment with the environment variable `EKS_CLUSTER_NAME`. This is always set, and does not need to be looked up each time.

An example of using this would look like so:

```
$ aws eks describe-cluster --name $EKS_CLUSTER_NAME
```

### Info and Caution Blocks

:::Info
Use info blocks for additional information
:::

:::Caution
Caution blocks also available
:::

:::Note
Note blocks are available
:::

### Badges

To mark your module as an independent module that users can begin with, place the following in the header of your markdown file:
```
---
...
sidebar_custom_props: {"module": true}
---
```

To mark your module as informational, with no actionable steps, place the following in the header of your markdown file:
```
---
...
sidebar_custom_props: {"info": true}
---
```