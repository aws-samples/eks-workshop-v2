---
title: ConfigMaps & Secrets
sidebar_position: 50
---

# ConfigMaps & Secrets - Managing Application Configuration

**ConfigMaps** and **Secrets** are Kubernetes objects that manage application configuration data. They separate configuration from application code, making applications more portable and secure.

## What Are ConfigMaps and Secrets?

### ConfigMaps
Store non-sensitive configuration data:
- **Environment variables** - Database URLs, API endpoints
- **Configuration files** - Application config, logging config
- **Command-line arguments** - Startup parameters

### Secrets
Store sensitive data:
- **Passwords** - Database passwords, API keys
- **Certificates** - TLS certificates and keys
- **Tokens** - Authentication tokens, OAuth secrets

## ConfigMap Anatomy

Here's a ConfigMap from our catalog service:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: catalog
  namespace: catalog
data:
  # Simple key-value pairs
  DB_HOST: "catalog-mysql"
  DB_NAME: "catalog"
  DB_READ_ONLY_REPLICA: "catalog-mysql"
  
  # Multi-line configuration file
  application.properties: |
    server.port=8080
    logging.level.root=INFO
    spring.datasource.url=jdbc:mysql://catalog-mysql:3306/catalog
```

## Secret Anatomy

Here's a Secret for database credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: catalog-db
  namespace: catalog
type: Opaque
data:
  # Base64 encoded values
  username: Y2F0YWxvZw==  # "catalog"
  password: ZGVmYXVsdA==  # "default"
```

## Types of Secrets

### Opaque (Default)
Generic secrets for arbitrary data:
```yaml
type: Opaque
data:
  api-key: bXktc2VjcmV0LWtleQ==
```

### TLS
For TLS certificates:
```yaml
type: kubernetes.io/tls
data:
  tls.crt: <certificate>
  tls.key: <private-key>
```

### Docker Registry
For container registry authentication:
```yaml
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <docker-config>
```

### Service Account Token
For service account authentication:
```yaml
type: kubernetes.io/service-account-token
```

## Exploring Configuration in Our Application

Let's examine the configuration in our retail store:

```bash
# See all ConfigMaps
$ kubectl get configmaps -A -l app.kubernetes.io/created-by=eks-workshop

# See all Secrets
$ kubectl get secrets -A -l app.kubernetes.io/created-by=eks-workshop

# Focus on catalog configuration
$ kubectl get configmap,secret -n catalog
```

### ConfigMap Details
```bash
$ kubectl describe configmap -n catalog catalog
```

### Secret Details
```bash
$ kubectl describe secret -n catalog catalog-db
```

Note: `describe` doesn't show secret values for security.

### Viewing Configuration Data
```bash
# View ConfigMap data
$ kubectl get configmap -n catalog catalog -o yaml

# View Secret data (base64 encoded)
$ kubectl get secret -n catalog catalog-db -o yaml

# Decode secret values
$ kubectl get secret -n catalog catalog-db -o jsonpath='{.data.username}' | base64 -d
```

## Using Configuration in Pods

Configuration can be injected into pods in several ways:

### Environment Variables
Inject individual keys as environment variables:
```yaml
spec:
  containers:
  - name: catalog
    env:
    # From ConfigMap
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: catalog
          key: DB_HOST
    # From Secret
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: catalog-db
          key: password
```

### Environment Variables (All Keys)
Inject all keys from a ConfigMap or Secret:
```yaml
spec:
  containers:
  - name: catalog
    envFrom:
    - configMapRef:
        name: catalog
    - secretRef:
        name: catalog-db
```

### Volume Mounts
Mount configuration as files:
```yaml
spec:
  containers:
  - name: catalog
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: config-volume
    configMap:
      name: catalog
  - name: secret-volume
    secret:
      secretName: catalog-db
```

## Creating Configuration

### Creating ConfigMaps
```bash
# From literal values
$ kubectl create configmap my-config \
  --from-literal=key1=value1 \
  --from-literal=key2=value2

# From files
$ kubectl create configmap my-config \
  --from-file=config.properties \
  --from-file=logging.conf

# From directories
$ kubectl create configmap my-config --from-file=config-dir/

# Declarative way (recommended)
$ kubectl apply -f configmap.yaml
```

### Creating Secrets
```bash
# From literal values
$ kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123

# From files
$ kubectl create secret generic my-secret \
  --from-file=username.txt \
  --from-file=password.txt

# TLS secret
$ kubectl create secret tls my-tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Docker registry secret
$ kubectl create secret docker-registry my-registry-secret \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com

# Declarative way (recommended)
$ kubectl apply -f secret.yaml
```

## Configuration Patterns

### Environment-Specific Configuration
Use different ConfigMaps for different environments:
```yaml
# development-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  environment: "development"
  debug: "true"
  database_url: "dev-db:5432"

---
# production-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  environment: "production"
  debug: "false"
  database_url: "prod-db:5432"
```

### Layered Configuration
Combine multiple ConfigMaps:
```yaml
spec:
  containers:
  - name: app
    envFrom:
    - configMapRef:
        name: common-config
    - configMapRef:
        name: environment-config
    - configMapRef:
        name: app-specific-config
```

### Configuration Files
Mount configuration files:
```yaml
# ConfigMap with configuration file
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    server {
        listen 80;
        location / {
            proxy_pass http://backend;
        }
    }

---
# Pod using the configuration
spec:
  containers:
  - name: nginx
    volumeMounts:
    - name: config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
  volumes:
  - name: config
    configMap:
      name: nginx-config
```

## Security Best Practices

### Secrets Security
1. **Use Secrets for sensitive data** - Never put passwords in ConfigMaps
2. **Limit access** - Use RBAC to control who can read secrets
3. **Encrypt at rest** - Enable etcd encryption
4. **Rotate regularly** - Update secrets periodically

### ConfigMap Security
1. **Validate input** - Don't trust configuration data blindly
2. **Use least privilege** - Only give access to needed configuration
3. **Audit access** - Monitor who accesses configuration

### Example RBAC for Configuration
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: config-reader
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["app-secrets"]  # Specific secrets only
```

## Configuration Updates

### Updating ConfigMaps
```bash
# Edit directly
$ kubectl edit configmap my-config

# Replace from file
$ kubectl create configmap my-config --from-file=config.properties --dry-run=client -o yaml | kubectl apply -f -

# Patch specific keys
$ kubectl patch configmap my-config -p '{"data":{"key1":"new-value"}}'
```

### Updating Secrets
```bash
# Edit directly (values are base64 encoded)
$ kubectl edit secret my-secret

# Replace from literal
$ kubectl create secret generic my-secret --from-literal=password=newpass --dry-run=client -o yaml | kubectl apply -f -
```

### Pod Restart After Updates
ConfigMaps and Secrets mounted as volumes update automatically, but environment variables don't. You may need to restart pods:
```bash
$ kubectl rollout restart deployment/my-app
```

## Testing Configuration

### Verify Environment Variables
```bash
# Check environment variables in a pod
$ kubectl exec -n catalog deployment/catalog -- env | grep DB_

# Check specific variable
$ kubectl exec -n catalog deployment/catalog -- printenv DB_HOST
```

### Verify Mounted Files
```bash
# List mounted configuration files
$ kubectl exec -n catalog deployment/catalog -- ls -la /etc/config/

# View configuration file content
$ kubectl exec -n catalog deployment/catalog -- cat /etc/config/application.properties
```

### Debug Configuration Issues
```bash
# Check if ConfigMap exists
$ kubectl get configmap my-config

# Check if Secret exists
$ kubectl get secret my-secret

# Verify pod has access
$ kubectl describe pod my-pod | grep -A 10 "Environment\|Mounts"
```

## Best Practices

### 1. Separate Configuration from Code
Never hardcode configuration in container images:
```yaml
# Good - externalized configuration
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: database_url

# Bad - hardcoded in image
# DATABASE_URL=prod-db:5432
```

### 2. Use Meaningful Names
Choose descriptive names for configuration:
```yaml
metadata:
  name: catalog-database-config  # Clear purpose
```

### 3. Organize by Environment
Use labels to organize configuration:
```yaml
metadata:
  labels:
    app: catalog
    environment: production
    config-type: database
```

### 4. Validate Configuration
Add validation to your applications:
```python
import os

database_url = os.getenv('DATABASE_URL')
if not database_url:
    raise ValueError("DATABASE_URL environment variable is required")
```

### 5. Document Configuration
Document required configuration:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  annotations:
    description: "Main application configuration"
    required-keys: "database_url,api_key,log_level"
data:
  database_url: "postgres://db:5432/app"
  log_level: "INFO"
```

## Troubleshooting Configuration

### Common Issues

**Pod Can't Start - Missing Configuration:**
```bash
$ kubectl describe pod my-pod
# Look for events about missing ConfigMaps or Secrets
```

**Environment Variables Not Set:**
```bash
$ kubectl exec my-pod -- env
# Verify environment variables are present
```

**Configuration Files Not Mounted:**
```bash
$ kubectl exec my-pod -- ls -la /etc/config/
# Check if files are mounted correctly
```

### Debug Commands
```bash
# Check ConfigMap data
$ kubectl get configmap my-config -o yaml

# Check Secret data (base64 encoded)
$ kubectl get secret my-secret -o yaml

# Verify pod configuration
$ kubectl get pod my-pod -o yaml | grep -A 20 "env\|volumes"
```

## Key Takeaways

- ConfigMaps store non-sensitive configuration data
- Secrets store sensitive data like passwords and certificates
- Configuration can be injected as environment variables or mounted files
- Separate configuration from application code for portability
- Use RBAC to control access to sensitive configuration
- Update pods after changing configuration if using environment variables

## Next Steps

Now that you understand all the core Kubernetes concepts, you're ready to see them work together in practice. Let's move on to [hands-on deployment](../first) where you'll apply these concepts to deploy and explore our retail store application.