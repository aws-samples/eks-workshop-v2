---
title: Getting Started
sidebar_position: 50
sidebar_custom_props: { "module": true }
description: "Learn the basics of running workloads on Amazon Elastic Kubernetes Service."
---

::required-time

Welcome to the first hands-on lab in the EKS workshop. The goal of this exercise is to prepare the IDE with necessary configurations and explore the structure.

Before we begin we need to run the following command to prepare our IDE environment and EKS cluster:

:::tip Prepare your environment for this section:

```bash
$ prepare-environment introduction/getting-started
```
This command will clone the EKS workshop Git repository into the IDE environment.
:::

<details>
<summary>What does prepare-environment do? (Click to expand)</summary>

The `prepare-environment` command is a crucial tool that sets up your lab environment for each workshop module. Here's what it does behind the scenes:

- **Repository Setup**: Downloads the latest EKS Workshop content from GitHub to `/eks-workshop/repository` and links Kubernetes manifests to `~/environment/eks-workshop`
- **Cluster Reset & Cleanup**: Resets the sample retail application to its base state. Removes any leftover resources from previous labs and restores EKS managed node groups to initial size (3 nodes).
- **Lab-Specific Infrastructure**: Ensure the target module is ready to use by creating any extra AWS resources using Terraform, deploying the required Kubernetes manifests, configuring environment variables, and installing necessary add-ons or components.

</details>

## Workshop Structure

After running `prepare-environment`, you'll have access to the workshop materials at `~/environment/eks-workshop/`. The workshop is organized into modular sections that you can complete in any order.

## Exploring Your EKS Cluster

Now that your environment is ready, let's explore the EKS cluster that's been provisioned for you. Run these commands to get familiar with your cluster:

### Cluster Information

First, let's verify your cluster connection and get basic information:

```bash
$ kubectl cluster-info
Kubernetes control plane is running at https://XXXXXXXXXXXXXXXXXXXXXXXXXX.gr7.us-west-2.eks.amazonaws.com
CoreDNS is running at https://XXXXXXXXXXXXXXXXXXXXXXXXXX.gr7.us-west-2.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Check the cluster version 
```bash
$ kubectl version
Client Version: v1.33.5
Kustomize Version: v5.6.0
Server Version: v1.33.5-eks-113cf36
```

Check worker nodes in the cluster

```bash
$ kubectl get nodes -o wide
NAME                                          STATUS   ROLES    AGE   VERSION               INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION                   CONTAINER-RUNTIME
ip-10-42-121-153.us-west-2.compute.internal   Ready    <none>   26h   v1.33.5-eks-113cf36   10.42.121.153   <none>        Amazon Linux 2023.9.20250929   6.12.46-66.121.amzn2023.x86_64   containerd://1.7.27
ip-10-42-141-241.us-west-2.compute.internal   Ready    <none>   26h   v1.33.5-eks-113cf36   10.42.141.241   <none>        Amazon Linux 2023.9.20250929   6.12.46-66.121.amzn2023.x86_64   containerd://1.7.27
ip-10-42-183-73.us-west-2.compute.internal    Ready    <none>   26h   v1.33.5-eks-113cf36   10.42.183.73    <none>        Amazon Linux 2023.9.20250929   6.12.46-66.121.amzn2023.x86_64   containerd://1.7.27
```

This shows your worker nodes, their Kubernetes version, internal/external IPs, and the container runtime being used.

### Explore Cluster Components

Let's look at the system components running in your cluster:

```bash
$ kubectl get pods -n kube-system
NAME                              READY   STATUS    RESTARTS   AGE
aws-node-8cz4d                    2/2     Running   0          26h
aws-node-jlg4q                    2/2     Running   0          26h
aws-node-vdc56                    2/2     Running   0          26h
coredns-7bf648ff5d-4fqv9          1/1     Running   0          26h
coredns-7bf648ff5d-bfwwf          1/1     Running   0          26h
kube-proxy-77ln2                  1/1     Running   0          26h
kube-proxy-7bwbj                  1/1     Running   0          26h
kube-proxy-jnhfx                  1/1     Running   0          26h
metrics-server-7fb96f5556-2k4lh   1/1     Running   0          26h
metrics-server-7fb96f5556-mpj78   1/1     Running   0          26h
```

You'll see essential components like:
- **CoreDNS** - Provides DNS services for the cluster
- **AWS Load Balancer Controller** - Manages AWS load balancers for services
- **VPC CNI** - Handles pod networking within your VPC
- **kube-proxy** - Manages network rules on each node

## Deploy the Sample Application

Let's deploy the retail store application to see Kubernetes in action. We'll use Kustomize, which is built into kubectl:

```bash wait=10
$ kubectl apply -k ~/environment/eks-workshop/base-application
```

After this is complete we can use `kubectl wait` to make sure all the components have started before we proceed:

```bash timeout=200
$ kubectl wait --for=condition=Ready --timeout=180s pods \
  -l app.kubernetes.io/created-by=eks-workshop -A
```

We'll now have a Namespace for each of our application components:

```bash
$ kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
NAME       STATUS   AGE
carts      Active   62s
catalog    Active   7m17s
checkout   Active   62s
orders     Active   62s
other      Active   62s
ui         Active   62s
```

We can also see all of the Deployments created for the components:

```bash
$ kubectl get deployment -l app.kubernetes.io/created-by=eks-workshop -A
NAMESPACE   NAME                READY   UP-TO-DATE   AVAILABLE   AGE
carts       carts               1/1     1            1           90s
carts       carts-dynamodb      1/1     1            1           90s
catalog     catalog             1/1     1            1           7m46s
checkout    checkout            1/1     1            1           90s
checkout    checkout-redis      1/1     1            1           90s
orders      orders              1/1     1            1           90s
orders      orders-postgresql   1/1     1            1           90s
ui          ui                  1/1     1            1           90s
```

The sample application is now deployed and ready to provide a foundation for us to use in the rest of the labs in this workshop!

## What's Next?

Your EKS cluster is ready and the sample application is deployed! You can now jump into any workshop module based on your learning goals.

:::tip
Each module is self-contained and includes its own `prepare-environment` command to set up the required resources. You can complete them in any order!
:::
