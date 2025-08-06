---
title: Roles
sidebar_position: 10
---

# Roles and ClusterRoles

Roles and ClusterRoles define what actions can be performed on which resources. Roles are namespace-scoped, while ClusterRoles are cluster-wide.

## Understanding Roles vs ClusterRoles

| Aspect | Role | ClusterRole |
|--------|------|-------------|
| **Scope** | Single namespace | Entire cluster |
| **Resources** | Namespaced resources | All resources + cluster resources |
| **Use Cases** | Team permissions, app access | Admin access, system components |
| **Binding** | RoleBinding only | RoleBinding or ClusterRoleBinding |

## Creating Roles

### Basic Role Structure

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: pod-reader
rules:
- apiGroups: [""]          # Core API group
  resources: ["pods"]      # Resource type
  verbs: ["get", "list"]   # Allowed actions
```

### Role with Multiple Rules

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: developer-role
rules:
# Pod management
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec"]
  verbs: ["get", "list", "create", "delete", "watch"]
# Service management
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
# Deployment management
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch", "delete", "watch"]
# ConfigMap and Secret access
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
EOF
```

## Creating ClusterRoles

### Basic ClusterRole

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
EOF
```

### Comprehensive ClusterRole

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin-custom
rules:
# Core resources
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
# Apps resources
- apiGroups: ["apps"]
  resources: ["*"]
  verbs: ["*"]
# Extensions resources
- apiGroups: ["extensions"]
  resources: ["*"]
  verbs: ["*"]
# RBAC resources
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
# Custom resources
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["customresourcedefinitions"]
  verbs: ["*"]
EOF
```

## API Groups and Resources

### Core API Group ("")
```yaml
rules:
- apiGroups: [""]
  resources: 
  - "pods"
  - "services"
  - "configmaps"
  - "secrets"
  - "persistentvolumes"
  - "persistentvolumeclaims"
  - "nodes"
  - "namespaces"
  verbs: ["get", "list", "watch"]
```

### Apps API Group
```yaml
rules:
- apiGroups: ["apps"]
  resources:
  - "deployments"
  - "replicasets"
  - "statefulsets"
  - "daemonsets"
  verbs: ["get", "list", "create", "update", "patch", "delete"]
```

### Batch API Group
```yaml
rules:
- apiGroups: ["batch"]
  resources:
  - "jobs"
  - "cronjobs"
  verbs: ["get", "list", "create", "update", "patch", "delete"]
```

### Networking API Group
```yaml
rules:
- apiGroups: ["networking.k8s.io"]
  resources:
  - "networkpolicies"
  - "ingresses"
  verbs: ["get", "list", "create", "update", "patch", "delete"]
```

## Verbs (Actions)

### Read Operations
```yaml
verbs: ["get", "list", "watch"]
```
- **get** - Retrieve a specific resource
- **list** - List resources of a type
- **watch** - Watch for changes to resources

### Write Operations
```yaml
verbs: ["create", "update", "patch", "delete"]
```
- **create** - Create new resources
- **update** - Replace entire resource
- **patch** - Modify parts of a resource
- **delete** - Remove resources

### Special Verbs
```yaml
verbs: ["use", "bind", "escalate", "impersonate"]
```
- **use** - Use PodSecurityPolicies, NetworkPolicies
- **bind** - Create RoleBindings/ClusterRoleBindings
- **escalate** - Create roles with more permissions than you have
- **impersonate** - Act as another user/group/service account

## Resource Names

Restrict access to specific resource instances:

```yaml
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["my-secret", "another-secret"]
  verbs: ["get", "list"]
```

## Subresources

Access specific subresources:

```yaml
rules:
# Pod logs
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
# Pod exec
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
# Service proxy
- apiGroups: [""]
  resources: ["services/proxy"]
  verbs: ["get", "create"]
```

## Real-World Role Examples

### Developer Role
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: developer
rules:
# Application resources
- apiGroups: ["", "apps"]
  resources: ["pods", "services", "deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch", "delete", "watch"]
# Configuration
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
# Secrets (read-only)
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
# Logs and debugging
- apiGroups: [""]
  resources: ["pods/log", "pods/exec"]
  verbs: ["get", "create"]
EOF
```

### QA Tester Role
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: testing
  name: qa-tester
rules:
# Read access to applications
- apiGroups: ["", "apps"]
  resources: ["pods", "services", "deployments"]
  verbs: ["get", "list", "watch"]
# Access to logs for debugging
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
# Port forwarding for testing
- apiGroups: [""]
  resources: ["pods/portforward"]
  verbs: ["create"]
# Test data management
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["test-data", "test-config"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
EOF
```

### Monitoring Role
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring
rules:
# Read access to all resources for metrics
- apiGroups: [""]
  resources: ["nodes", "pods", "services", "endpoints", "namespaces"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
  verbs: ["get", "list", "watch"]
# Metrics endpoints
- nonResourceURLs: ["/metrics", "/metrics/*"]
  verbs: ["get"]
EOF
```

### CI/CD Deployment Role
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: deployer
rules:
# Deployment management
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
# Service management
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "create", "update", "patch"]
# Configuration management
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "patch"]
# Read access to pods for status checking
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF
```

## Aggregated ClusterRoles

Combine multiple ClusterRoles using aggregation:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-aggregated
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.example.com/aggregate-to-monitoring: "true"
rules: [] # Rules are automatically filled by aggregation
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-pods
  labels:
    rbac.example.com/aggregate-to-monitoring: "true"
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-services
  labels:
    rbac.example.com/aggregate-to-monitoring: "true"
rules:
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch"]
EOF
```

## Viewing and Managing Roles

### List Roles and ClusterRoles
```bash
# List roles in current namespace
$ kubectl get roles

# List roles in all namespaces
$ kubectl get roles -A

# List cluster roles
$ kubectl get clusterroles
```

### Describe Role Details
```bash
$ kubectl describe role developer -n development
$ kubectl describe clusterrole monitoring
```

### View Role YAML
```bash
$ kubectl get role developer -n development -o yaml
$ kubectl get clusterrole monitoring -o yaml
```

## Testing Role Permissions

### Check API Resources
```bash
# List all API resources
$ kubectl api-resources

# List API resources with verbs
$ kubectl api-resources -o wide

# List resources in specific API group
$ kubectl api-resources --api-group=apps
```

### Validate Role Rules
```bash
# Check if role allows specific action
$ kubectl auth can-i create pods --as=system:serviceaccount:development:developer-sa

# Check permissions for specific role
$ kubectl auth can-i create deployments --as=system:serviceaccount:development:developer-sa -n development
```

## Best Practices

### 1. Principle of Least Privilege
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

### 2. Use Descriptive Names
```yaml
# Good - clear purpose
metadata:
  name: frontend-developer
  
# Avoid - generic names
metadata:
  name: role1
```

### 3. Group Related Permissions
```yaml
rules:
# Group by functionality
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "watch"]
```

### 4. Document Role Purpose
```yaml
metadata:
  name: database-operator
  annotations:
    description: "Allows management of database-related resources"
    team: "platform"
    created-by: "admin@company.com"
```

### 5. Regular Role Audits
```bash
# List all roles and their permissions
$ kubectl get roles,clusterroles -A -o yaml > roles-audit.yaml

# Review unused roles
$ kubectl get rolebindings,clusterrolebindings -A -o yaml | grep -E "roleRef|name"
```

## Troubleshooting

### Permission Denied Errors
```bash
# Check what permissions you have
$ kubectl auth can-i --list

# Check specific permission
$ kubectl auth can-i create pods -n development

# Check as different user
$ kubectl auth can-i create pods --as=user@example.com
```

### Role Not Working
```bash
# Verify role exists
$ kubectl get role <role-name> -n <namespace>

# Check role rules
$ kubectl describe role <role-name> -n <namespace>

# Verify role binding exists
$ kubectl get rolebinding -n <namespace>
```

## Cleanup

Remove the example roles:

```bash
$ kubectl delete role developer qa-tester deployer -n development --ignore-not-found
$ kubectl delete role deployer -n production --ignore-not-found
$ kubectl delete role qa-tester -n testing --ignore-not-found
$ kubectl delete clusterrole node-reader cluster-admin-custom monitoring monitoring-aggregated monitoring-pods monitoring-services --ignore-not-found
```

## What's Next?

Now that you understand how to create Roles and ClusterRoles, let's learn about [Bindings](./bindings) to understand how to assign these permissions to users, groups, and service accounts.