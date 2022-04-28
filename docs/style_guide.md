# EKS Workshop - Style Guide

This document provides a style guide that should be used when creating or modifying content for the workshop in order to maintain a consistent experience throughout the content.

## Scripts/Commands

This section provides guidelines related to the commands and scripts learners are instructed to use during the workshop content.

### Command blocks

All commands to the executed by the user should be contained within a Markdown `code` block specifying the language as `bash`. This is being used by tools like automated testing so must be consistent.

For example instead of this:

````
```
kubectl get pods
```
````

It is preferable to use this:

````
```bash
kubectl get pods
```
````

Enter the command exactly as it should be run by the learner, do not prefix it with anything in the interest of styling.

For example instead of this:

````
```bash
[root@b32a35acd6b6 /]$ kubectl get pods
```
````

It is preferable to use this:

````
```bash
kubectl get pods
```
````

Expected output from a command the learner should run must be displayed in a separate `code` block:

````
Please run this command:

```bash
kubectl get pods
```

And expect this output:

```
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
helm upgrade --install --namespace karpenter \
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