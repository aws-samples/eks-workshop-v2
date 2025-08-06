---
title: Bindings
sidebar_position: 20
---

# RoleBindings and ClusterRoleBindings

RoleBindings and ClusterRoleBindings connect Roles/ClusterRoles to subjects (users, groups, or service accounts). They answer the question "who gets what permissions?"

## Understanding Bindings

| Binding Type | Scope | Can Bind | Use Cases |
|--------------|-------|----------|-----------|
| **RoleBinding** | Namespace | Role or ClusterRole | Team access to namespace |
| **ClusterRoleBinding** | Cluster | ClusterRole only | Admin access, system components |

## RoleBinding

RoleBindings grant permissions within a specific namespace.

### Basic RoleBinding Structure

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development
subjects:
- kind: User
  name: alice@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
```

### Creating RoleBindings

#### Bind Role to User
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-alice
  namespace: development
subjects:
- kind: User
  name: alice@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

#### Bind Role to Group
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers-group
  namespace: development
subjects:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

#### Bind Role to Service Account
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: development
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-binding
  namespace: development
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: development
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

## ClusterRoleBinding

ClusterRoleBindings grant permissions across the entire cluster.

### Basic ClusterRoleBinding
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-alice
subjects:
- kind: User
  name: alice@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Multiple Subjects
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-team
subjects:
- kind: User
  name: alice@company.com
  apiGroup: rbac.authorization.k8s.io
- kind: User
  name: bob@company.com
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: monitoring-team
  apiGroup: rbac.authorization.k8s.io
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: monitoring-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```

## Using ClusterRole in RoleBinding

You can bind a ClusterRole to a namespace using RoleBinding:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: admin-in-development
  namespace: development
subjects:
- kind: User
  name: alice@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole  # Note: ClusterRole, not Role
  name: admin
  apiGroup: rbac.authorization.k8s.io
EOF
```

This grants admin permissions only within the `development` namespace.

## Service Accounts

Service accounts provide identity for pods and applications.

### Creating Service Accounts
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: web-app-sa
  namespace: production
  annotations:
    description: "Service account for web application"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: database-backup-sa
  namespace: production
  annotations:
    description: "Service account for database backup jobs"
EOF
```

### Using Service Accounts in Pods
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      serviceAccountName: web-app-sa  # Use custom service account
      containers:
      - name: web
        image: nginx
```

## Real-World Examples

### Example 1: Development Team Setup

```bash
$ cat << EOF | kubectl apply -f -
# Namespace for the team
apiVersion: v1
kind: Namespace
metadata:
  name: team-alpha
---
# Role with appropriate permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: team-alpha
  name: team-alpha-developer
rules:
- apiGroups: ["", "apps", "extensions"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["batch"]
  resources: ["jobs", "cronjobs"]
  verbs: ["*"]
---
# RoleBinding for the team
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-alpha-developers
  namespace: team-alpha
subjects:
- kind: Group
  name: team-alpha
  apiGroup: rbac.authorization.k8s.io
- kind: User
  name: alice@company.com
  apiGroup: rbac.authorization.k8s.io
- kind: User
  name: bob@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: team-alpha-developer
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Example 2: CI/CD Pipeline

```bash
$ cat << EOF | kubectl apply -f -
# Service account for CI/CD
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cicd-deployer
  namespace: production
---
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
- apiGroups: [""]
  resources: ["services", "configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
# RoleBinding for CI/CD
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cicd-deployer-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: cicd-deployer
  namespace: production
roleRef:
  kind: Role
  name: deployer
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Example 3: Read-Only Monitoring

```bash
$ cat << EOF | kubectl apply -f -
# ClusterRole for monitoring
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "services", "endpoints", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics", "/metrics/*"]
  verbs: ["get"]
---
# Service account for monitoring
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
---
# ClusterRoleBinding for monitoring
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-monitoring
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: monitoring-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Example 4: Multi-Namespace Access

```bash
$ cat << EOF | kubectl apply -f -
# ClusterRole for cross-namespace access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cross-namespace-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
# RoleBinding in namespace 1
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: alice-reader
  namespace: development
subjects:
- kind: User
  name: alice@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cross-namespace-reader
  apiGroup: rbac.authorization.k8s.io
---
# RoleBinding in namespace 2
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: alice-reader
  namespace: staging
subjects:
- kind: User
  name: alice@company.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cross-namespace-reader
  apiGroup: rbac.authorization.k8s.io
EOF
```

## Managing Bindings with kubectl

### Create RoleBinding with kubectl
```bash
# Bind role to user
$ kubectl create rolebinding developer-alice \
  --role=developer-role \
  --user=alice@company.com \
  --namespace=development

# Bind role to group
$ kubectl create rolebinding developers-group \
  --role=developer-role \
  --group=developers \
  --namespace=development

# Bind role to service account
$ kubectl create rolebinding app-binding \
  --role=developer-role \
  --serviceaccount=development:app-service-account \
  --namespace=development
```

### Create ClusterRoleBinding with kubectl
```bash
# Bind cluster role to user
$ kubectl create clusterrolebinding cluster-admin-alice \
  --clusterrole=cluster-admin \
  --user=alice@company.com

# Bind cluster role to service account
$ kubectl create clusterrolebinding prometheus-monitoring \
  --clusterrole=monitoring-reader \
  --serviceaccount=monitoring:prometheus
```

## Viewing and Managing Bindings

### List Bindings
```bash
# List role bindings in current namespace
$ kubectl get rolebindings

# List role bindings in all namespaces
$ kubectl get rolebindings -A

# List cluster role bindings
$ kubectl get clusterrolebindings
```

### Describe Bindings
```bash
$ kubectl describe rolebinding developer-alice -n development
$ kubectl describe clusterrolebinding cluster-admin-alice
```

### View Binding YAML
```bash
$ kubectl get rolebinding developer-alice -n development -o yaml
$ kubectl get clusterrolebinding cluster-admin-alice -o yaml
```

## Testing Permissions

### Check User Permissions
```bash
# Check as specific user
$ kubectl auth can-i create pods --as=alice@company.com -n development

# Check service account permissions
$ kubectl auth can-i create deployments --as=system:serviceaccount:production:cicd-deployer -n production

# List all permissions for user
$ kubectl auth can-i --list --as=alice@company.com -n development
```

### Impersonate Users
```bash
# Run commands as different user
$ kubectl get pods --as=alice@company.com -n development

# Run commands as service account
$ kubectl get pods --as=system:serviceaccount:production:web-app-sa -n production
```

## Troubleshooting Bindings

### Permission Denied
```bash
# Check if binding exists
$ kubectl get rolebindings,clusterrolebindings -A | grep alice

# Verify role exists
$ kubectl get role developer-role -n development

# Check role permissions
$ kubectl describe role developer-role -n development
```

### Service Account Issues
```bash
# Check if service account exists
$ kubectl get serviceaccount -n production

# Verify pod is using correct service account
$ kubectl get pod <pod-name> -o yaml | grep serviceAccount

# Check service account permissions
$ kubectl auth can-i create pods --as=system:serviceaccount:production:web-app-sa
```

### Binding Not Working
```bash
# Verify binding syntax
$ kubectl get rolebinding <binding-name> -o yaml

# Check subjects and roleRef
$ kubectl describe rolebinding <binding-name>

# Validate role reference
$ kubectl get role <role-name> -n <namespace>
```

## Best Practices

### 1. Use Groups Instead of Individual Users
```yaml
# Good - use groups
subjects:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io

# Avoid - individual users
subjects:
- kind: User
  name: alice@company.com
- kind: User
  name: bob@company.com
```

### 2. Principle of Least Privilege
```yaml
# Good - specific namespace access
kind: RoleBinding
metadata:
  namespace: development

# Avoid - cluster-wide access when not needed
kind: ClusterRoleBinding
```

### 3. Use Descriptive Names
```yaml
# Good - descriptive names
metadata:
  name: frontend-developers-development
  
# Avoid - generic names
metadata:
  name: binding1
```

### 4. Document Bindings
```yaml
metadata:
  name: cicd-deployer-binding
  annotations:
    description: "Allows CI/CD pipeline to deploy applications"
    team: "platform"
    created-by: "admin@company.com"
```

### 5. Regular Access Reviews
```bash
# Audit all bindings
$ kubectl get rolebindings,clusterrolebindings -A -o yaml > bindings-audit.yaml

# Find bindings for specific user
$ kubectl get rolebindings,clusterrolebindings -A -o yaml | grep -B5 -A5 "alice@company.com"
```

### 6. Use Service Accounts for Applications
```yaml
# Always specify service account for applications
spec:
  serviceAccountName: my-app-sa
  containers:
  - name: app
    image: my-app:latest
```

## Cleanup

Remove the example bindings and resources:

```bash
$ kubectl delete namespace team-alpha --ignore-not-found
$ kubectl delete serviceaccount web-app-sa database-backup-sa -n production --ignore-not-found
$ kubectl delete serviceaccount cicd-deployer -n production --ignore-not-found
$ kubectl delete serviceaccount prometheus -n monitoring --ignore-not-found
$ kubectl delete rolebinding developer-alice developers-group app-binding -n development --ignore-not-found
$ kubectl delete rolebinding admin-in-development -n development --ignore-not-found
$ kubectl delete rolebinding cicd-deployer-binding -n production --ignore-not-found
$ kubectl delete rolebinding alice-reader -n development --ignore-not-found
$ kubectl delete rolebinding alice-reader -n staging --ignore-not-found
$ kubectl delete clusterrolebinding cluster-admin-alice monitoring-team prometheus-monitoring --ignore-not-found
$ kubectl delete clusterrole monitoring-reader cross-namespace-reader --ignore-not-found
```

## What's Next?

Congratulations! You've completed the Advanced Concepts section and learned about:

- **Workloads** - StatefulSets, DaemonSets, and Jobs for specialized use cases
- **Nodes** - Advanced scheduling, taints, tolerations, and node management  
- **RBAC** - Role-Based Access Control for security and governance

You now have a comprehensive understanding of Kubernetes concepts from fundamentals to advanced topics. You're ready to:

1. **Continue to EKS-specific features** in the [Fundamentals module](/docs/fundamentals)
2. **Learn about deployment tooling** in [Kustomize](../../kustomize) and [Helm](../../helm)
3. **Apply these concepts** in production environments

The foundation you've built here will be essential for all subsequent workshop modules!