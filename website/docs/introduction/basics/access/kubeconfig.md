---
title: kubeconfig
sidebar_position: 20
description: "Learn how to configure access to Kubernetes clusters using kubeconfig and AWS EKS integration."
---

# Cluster Access & Configuration

To use kubectl with a Kubernetes cluster, you need to configure access using a **kubeconfig** file.

The kubeconfig file is a YAML configuration file that tells kubectl:
- **Where** to find your Kubernetes cluster (API server endpoint)
- **How** to authenticate with it (credentials)
- **Which** cluster and user to use by default (context)

### kubeconfig Structure

A kubeconfig file contains three main sections:

```yaml
apiVersion: v1
kind: Config
clusters:          # Information about Kubernetes clusters
- name: my-cluster
  cluster:
    server: https://kubernetes-api-server:6443
    certificate-authority-data: <base64-encoded-ca-cert>

users:             # Authentication credentials for different users
- name: my-user
  user:
    token: <authentication-token>
    # OR client-certificate-data and client-key-data
    # OR exec command for dynamic authentication

contexts:          # Combinations of cluster + user + namespace
- name: my-context
  context:
    cluster: my-cluster
    user: my-user
    namespace: default

current-context: my-context  # Which context to use by default
```

### Key Components Explained

**Clusters**: Define how to connect to Kubernetes API servers
- **server**: The API server URL (e.g., `https://my-cluster.example.com:6443`)
- **certificate-authority**: CA certificate to verify the server's identity
- **insecure-skip-tls-verify**: Skip TLS verification (not recommended for production)

**Users**: Define authentication methods
- **token**: Bearer token authentication
- **client-certificate/client-key**: Mutual TLS authentication
- **username/password**: Basic authentication (rarely used)
- **exec**: External command for dynamic authentication (like AWS CLI)

**Contexts**: Combine cluster + user + optional default namespace
- Allows you to easily switch between different clusters or users
- Can set a default namespace to avoid specifying `-n` repeatedly

### Managing Multiple Clusters

kubeconfig supports multiple clusters, users, and contexts in a single file:

```bash
# View your complete kubeconfig
$ kubectl config view

# List all available contexts
$ kubectl config get-contexts

# Check current context
$ kubectl config current-context
```

Additional commands:
```
# Switch between contexts
$ kubectl config use-context <context-name>

# Set default namespace for current context
$ kubectl config set-context --current --namespace=<namespace>
```

### kubeconfig File Location

By default, kubectl looks for kubeconfig at:
- `~/.kube/config` (Linux/macOS)
- `%USERPROFILE%\.kube\config` (Windows)

You can override this with:
- `KUBECONFIG` environment variable
- `--kubeconfig` flag with kubectl commands

## EKS-Specific Configuration

Amazon EKS integrates seamlessly with the standard kubeconfig pattern but adds AWS-specific authentication.

### AWS CLI Integration

For EKS clusters, AWS CLI provides a convenient way to configure kubectl:

```bash
# Configure kubectl for your EKS cluster
$ aws eks update-kubeconfig --region us-west-2 --name eks-workshop

# Verify the connection
$ kubectl get nodes
```

### What AWS CLI Does

When you run `aws eks update-kubeconfig`, it:

1. **Retrieves cluster information** from the EKS API
2. **Updates your kubeconfig file** (`~/.kube/config`)
3. **Sets up AWS authentication** using the `aws eks get-token` command

### EKS kubeconfig Structure

Here's what an EKS entry looks like in your kubeconfig:

```yaml
clusters:
- cluster:
    certificate-authority-data: <base64-ca-cert>
    server: https://ABC123.gr7.us-west-2.eks.amazonaws.com
  name: arn:aws:eks:us-west-2:123456789012:cluster/eks-workshop

users:
- name: arn:aws:eks:us-west-2:123456789012:cluster/eks-workshop
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
      - eks
      - get-token
      - --cluster-name
      - eks-workshop
      - --region
      - us-west-2

contexts:
- context:
    cluster: arn:aws:eks:us-west-2:123456789012:cluster/eks-workshop
    user: arn:aws:eks:us-west-2:123456789012:cluster/eks-workshop
  name: arn:aws:eks:us-west-2:123456789012:cluster/eks-workshop
```

### EKS Authentication Flow

When you run kubectl commands with EKS:

1. **kubectl** reads the kubeconfig file
2. **Executes** `aws eks get-token` command
3. **AWS CLI** uses your AWS credentials to get a temporary token
4. **kubectl** uses this token to authenticate with the EKS API server
5. **EKS** validates the token and maps it to Kubernetes RBAC permissions

### AWS Credentials for EKS

EKS authentication relies on your AWS credentials, which can come from:
- **AWS CLI profiles** (`~/.aws/credentials`)
- **Environment variables** (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- **IAM roles** (EC2 instance profiles, EKS service accounts)
- **AWS SSO** sessions

### Viewing Your EKS Configuration

```bash
# See your current kubeconfig (including EKS entries)
$ kubectl config view

# Check which EKS cluster you're connected to
$ kubectl config current-context

# Test your connection
$ kubectl get nodes

# Get cluster information
$ kubectl cluster-info
```

## Key Concepts to Remember

### kubeconfig Fundamentals
- **kubeconfig file** is the standard way Kubernetes stores cluster connection information
- **Three main components**: clusters (where), users (who), contexts (which combination)
- **Works the same** across all Kubernetes distributions (EKS, GKE, AKS, self-managed)
- **File location**: `~/.kube/config` by default, customizable via `KUBECONFIG` environment variable

### EKS Integration
- **AWS CLI integration** uses standard kubeconfig with AWS-specific authentication via `aws eks get-token`
- **Dynamic authentication** - tokens are generated on-demand using your AWS credentials
- **No static credentials** stored in kubeconfig - more secure than traditional approaches

### Context Management
- **Contexts** combine cluster + user + optional namespace for easy switching
- **Multiple clusters** can be managed from a single kubeconfig file
- **Default namespace** can be set per context to avoid repetitive `-n` flags
