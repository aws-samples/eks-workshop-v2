---
title: RBAC
sidebar_position: 30
---

# Role-Based Access Control (RBAC)

RBAC is Kubernetes' method for regulating access to resources based on the roles of individual users or service accounts. It's essential for security, compliance, and multi-tenant environments.

## Why RBAC Matters

### Security
- **Principle of least privilege** - Users get only necessary permissions
- **Attack surface reduction** - Limit potential damage from compromised accounts
- **Audit trails** - Track who can access what resources

### Compliance
- **Regulatory requirements** - Meet SOC2, PCI-DSS, HIPAA standards
- **Corporate policies** - Enforce organizational access controls
- **Separation of duties** - Prevent conflicts of interest

### Multi-tenancy
- **Team isolation** - Separate development teams and environments
- **Resource boundaries** - Prevent accidental cross-team access
- **Cost allocation** - Track resource usage by team

## RBAC Components

| Component | Scope | Purpose |
|-----------|-------|---------|
| **Role** | Namespace | Define permissions within a namespace |
| **ClusterRole** | Cluster | Define permissions across the cluster |
| **RoleBinding** | Namespace | Bind Role to subjects in a namespace |
| **ClusterRoleBinding** | Cluster | Bind ClusterRole to subjects cluster-wide |
| **ServiceAccount** | Namespace | Identity for pods and applications |

## RBAC Flow

```
Subject (User/Group/ServiceAccount) 
    ↓
RoleBinding/ClusterRoleBinding
    ↓
Role/ClusterRole (defines permissions)
    ↓
Resources (pods, services, etc.)
```

## Key Concepts

### Subjects
Who is requesting access:
- **Users** - Human users (managed outside Kubernetes)
- **Groups** - Collections of users
- **ServiceAccounts** - Pod identities (managed by Kubernetes)

### Resources
What is being accessed:
- **API resources** - pods, services, deployments, etc.
- **Non-resource URLs** - /api, /healthz, /metrics
- **Resource names** - Specific resource instances

### Verbs
What actions are allowed:
- **get, list, watch** - Read operations
- **create, update, patch** - Write operations
- **delete, deletecollection** - Delete operations
- **use** - Special verb for some resources

## Default RBAC in EKS

EKS comes with several default roles:

### System Roles
```bash
$ kubectl get clusterroles | grep system:
system:admin                    # Full admin access
system:basic-user              # Basic authenticated user
system:discovery               # Discovery API access
system:node                    # Node agent permissions
```

### AWS-Specific Roles
```bash
$ kubectl get clusterroles | grep aws
aws-load-balancer-controller   # ALB controller permissions
aws-node                       # VPC CNI permissions
ebs-csi-controller-role       # EBS CSI driver permissions
```

## Sections

- **[Roles](./roles)** - Create and manage Roles and ClusterRoles
- **[Bindings](./bindings)** - Bind roles to users and service accounts

## Real-World Scenarios

### Scenario 1: Development Team Access
A development team needs access to their namespace but not others:

```yaml
# Role for namespace-specific access
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev-team
  name: dev-team-role
rules:
- apiGroups: ["", "apps", "extensions"]
  resources: ["*"]
  verbs: ["*"]
```

### Scenario 2: Read-Only Monitoring
Monitoring tools need read-only access across the cluster:

```yaml
# ClusterRole for read-only access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services", "nodes"]
  verbs: ["get", "list", "watch"]
```

### Scenario 3: CI/CD Pipeline
CI/CD needs to deploy applications but not manage cluster resources:

```yaml
# Role for deployment permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: deployer
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
```

## Security Best Practices

### 1. Principle of Least Privilege
Grant only the minimum permissions needed:

```yaml
# Good - specific permissions
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

# Avoid - overly broad permissions
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

### 2. Use Namespaces for Isolation
```yaml
# Namespace-scoped role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: team-a
  name: team-a-role
```

### 3. Regular Access Reviews
```bash
# Audit who has access to what
kubectl get rolebindings,clusterrolebindings -A -o wide
```

### 4. Use Service Accounts for Applications
```yaml
# Dedicated service account for each application
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: production
```

## Testing RBAC

### Check Your Permissions
```bash
# Check if you can create pods
$ kubectl auth can-i create pods

# Check permissions for specific user
$ kubectl auth can-i create pods --as=user@example.com

# Check permissions in specific namespace
$ kubectl auth can-i create pods --namespace=production
```

### Impersonate Users
```bash
# Test as different user
$ kubectl get pods --as=developer@company.com

# Test as service account
$ kubectl get pods --as=system:serviceaccount:default:my-app-sa
```

## Common RBAC Patterns

### Pattern 1: Namespace Admin
Full control within a namespace:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: my-namespace
  name: namespace-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

### Pattern 2: Read-Only Access
View resources without modification:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: read-only
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
```

### Pattern 3: Specific Resource Access
Access to specific resource types:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: deployment-manager
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
```

## Troubleshooting RBAC

### Access Denied Errors
```bash
# Check current user permissions
$ kubectl auth whoami
$ kubectl auth can-i create pods

# Check specific resource access
$ kubectl auth can-i get pods --namespace=kube-system
```

### Debug Role Bindings
```bash
# List all role bindings
$ kubectl get rolebindings,clusterrolebindings -A

# Describe specific binding
$ kubectl describe rolebinding <binding-name> -n <namespace>
```

### Verify Service Account Permissions
```bash
# Check service account permissions
$ kubectl auth can-i create pods --as=system:serviceaccount:default:my-sa
```

## Getting Started

Let's start with [Roles](./roles) to learn how to create and manage permissions, then move on to [Bindings](./bindings) to understand how to assign those permissions to users and service accounts.