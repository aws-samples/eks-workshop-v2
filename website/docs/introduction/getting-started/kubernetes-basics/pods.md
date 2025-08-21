---
title: Pods
sidebar_position: 10
---

# Pods - Your Application Containers

A Pod is the smallest deployable unit in Kubernetes. It wraps one or more containers with shared networking and storage.

Our retail store application runs multiple microservices, each in their own Pods:

- **UI Pod** - Web interface for customers
- **Catalog Pod** - Product API and database
- **Cart Pod** - Shopping cart service  
- **Checkout Pod** - Order processing
- **Orders Pod** - Order management and database

Let's explore Pods by creating a simple one and examining how our retail store uses them.

## Creating Your First Pod

Let's create a simple Pod to understand the basics using [kubectl](https://kubernetes.io/docs/reference/kubectl/), the Kubernetes command-line tool:

```bash
$ kubectl run debug-pod --image=busybox --rm -it --restart=Never -- sh
```

Let's break down this command:

* `kubectl run` - Creates and runs a Pod
* `debug-pod` - Name of the Pod we're creating
* `--image=busybox` - Uses the BusyBox container image (a minimal Linux environment)
* `--rm` - Automatically delete the Pod when it exits
* `-it` - Interactive terminal (combines -i for interactive and -t for terminal)
* `--restart=Never` - Don't restart the Pod if it fails (creates a Pod, not a Deployment)
* `-- sh` - Run the sh shell command inside the container

This creates a temporary Pod running BusyBox. You're now inside the Pod's container:

```
/ # hostname
debug-pod
/ # ip addr show eth0
# Shows the Pod's unique IP address
/ # exit
```

