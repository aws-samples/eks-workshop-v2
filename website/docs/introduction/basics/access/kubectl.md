---
title: kubectl
sidebar_position: 10
description: "Learn essential kubectl commands for managing Kubernetes resources."
---

[kubectl](https://kubernetes.io/docs/reference/kubectl/) (pronounced "kube-control" or "kube-c-t-l") is the command-line tool that communicates with the Kubernetes API server. It translates your commands into API calls and presents the results in a human-readable format.

All kubectl commands follow this pattern:
```
kubectl [command] [type] [name] [flags]
```

Examples:
- `kubectl get pods` - List all pods
- `kubectl describe service ui` - Get detailed info about the ui service
- `kubectl apply -f deployment.yaml` - Create resources from a file

kubectl has excellent built-in documentation. Let's explore it:

```bash
$ kubectl
kubectl controls the Kubernetes cluster manager.

 Find more information at: https://kubernetes.io/docs/reference/kubectl/

Basic Commands (Beginner):
  create          Create a resource from a file or from stdin
  expose          Take a replication controller, service, deployment or pod and expose it as a new
Kubernetes service
  run             Run a particular image on the cluster
  set             Set specific features on objects

Basic Commands (Intermediate):
  explain         Get documentation for a resource
  get             Display one or many resources
  edit            Edit a resource on the server
  delete          Delete resources by file names, stdin, resources and names, or by resources and
label selector

Deploy Commands:
  rollout         Manage the rollout of a resource
  scale           Set a new size for a deployment, replica set, or replication controller
  autoscale       Auto-scale a deployment, replica set, stateful set, or replication controller

Cluster Management Commands:
  certificate     Modify certificate resources
  cluster-info    Display cluster information
  top             Display resource (CPU/memory) usage
  cordon          Mark node as unschedulable
  uncordon        Mark node as schedulable
  drain           Drain node in preparation for maintenance
  taint           Update the taints on one or more nodes

Troubleshooting and Debugging Commands:
  describe        Show details of a specific resource or group of resources
  logs            Print the logs for a container in a pod
  attach          Attach to a running container
  exec            Execute a command in a container
  port-forward    Forward one or more local ports to a pod
  proxy           Run a proxy to the Kubernetes API server
  cp              Copy files and directories to and from containers
  auth            Inspect authorization
  debug           Create debugging sessions for troubleshooting workloads and nodes
  events          List events

Advanced Commands:
  diff            Diff the live version against a would-be applied version
  apply           Apply a configuration to a resource by file name or stdin
  patch           Update fields of a resource
  replace         Replace a resource by file name or stdin
  wait            Experimental: Wait for a specific condition on one or many resources
  kustomize       Build a kustomization target from a directory or URL

Settings Commands:
  label           Update the labels on a resource
  annotate        Update the annotations on a resource
  completion      Output shell completion code for the specified shell (bash, zsh, fish, or
powershell)

Subcommands provided by plugins:
  connect       The command connect is a plugin installed by the user

Other Commands:
  api-resources   Print the supported API resources on the server
  api-versions    Print the supported API versions on the server, in the form of "group/version"
  config          Modify kubeconfig files
  plugin          Provides utilities for interacting with plugins
  version         Print the client and server version information

Usage:
  kubectl [flags] [options]

Use "kubectl <command> --help" for more information about a given command.
Use "kubectl options" for a list of global command-line options (applies to all commands).
```

`kubectl` organizes commands into logical categories. Understanding these categories helps you find the right command for any task.
1. Basic Commands (Beginner & Intermediate)
2. Deploy Commands
3. Cluster Management Commands
4. Troubleshooting and Debugging Commands
5. Advanced Commands
6. Settings Commands
7. Other Commands

### Getting Help
kubectl has excellent built-in help:
```bash
# See all command categories
$ kubectl --help

# Get help for specific commands
$ kubectl get --help
$ kubectl apply --help

# Get resource documentation
$ kubectl explain pod
$ kubectl explain deployment.spec.template
```

## Workshop Patterns

Throughout this workshop, you'll frequently use these kubectl commands:

- `kubectl apply -k` for Kustomize deployments
- `kubectl get pods -n <namespace>` for checking application status
- `kubectl describe` and `kubectl logs` for troubleshooting
- `kubectl port-forward` for accessing applications locally

## Key Concepts to Remember

- **Command pattern**: `kubectl [command] [type] [name] [flags]` - all commands follow this structure
- **Get help**: Use `kubectl --help` or `kubectl <command> --help` to discover options
- **Declarative approach**: Use `kubectl apply -f` for production deployments
- **Namespace awareness**: Always specify `-n <namespace>` or use `-A` for all namespaces
- **Essential commands**: `get`, `describe`, `logs`, `apply`, `port-forward` cover most daily tasks

Now that you understand kubectl commands, you can learn more about [how kubectl connects to clusters](../cluster-access), or jump ahead to explore the core Kubernetes resources, starting with [Namespaces](../../namespaces) for organizing your resources.