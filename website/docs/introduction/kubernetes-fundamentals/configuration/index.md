---
title: Configuration
sidebar_position: 50
---

# Configuration

Applications need configuration data and sometimes sensitive information like passwords or API keys. Kubernetes provides ConfigMaps and Secrets to manage this data separately from your application code.

## Why External Configuration?

Separating configuration from code provides several benefits:

- **Environment flexibility** - Same image, different configs for dev/staging/prod
- **Security** - Sensitive data stored separately and encrypted
- **Updates without rebuilds** - Change config without rebuilding images
- **Reusability** - Share configuration across multiple applications
- **Version control** - Track configuration changes

## ConfigMaps

ConfigMaps store non-sensitive configuration data as key-value pairs.

### Creating ConfigMaps

#### From literal values
```bash
$ kubectl create configmap app-config \
  --from-literal=database_url=postgresql://localhost:5432/mydb \
  --from-literal=debug_mode=true \
  --from-literal=max_connections=100
```

#### From files
```bash
$ echo "server_name=web-server" > app.properties
$ echo "port=8080" >> app.properties
$ kubectl create configmap app-config-file --from-file=app.properties
```

#### From directories
```bash
$ mkdir config
$ echo "log_level=info" > config/logging.conf
$ echo "cache_size=256MB" > config/cache.conf
$ kubectl create configmap app-config-dir --from-file=config/
```

#### Declaratively with YAML
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-yaml
data:
  database_url: "postgresql://localhost:5432/mydb"
  debug_mode: "true"
  max_connections: "100"
  app.properties: |
    server_name=web-server
    port=8080
    timeout=30
EOF
```

### Viewing ConfigMaps

```bash
$ kubectl get configmaps
$ kubectl describe configmap app-config
$ kubectl get configmap app-config -o yaml
```

## Secrets

Secrets store sensitive data like passwords, tokens, and keys. They're similar to ConfigMaps but designed for confidential data.

### Creating Secrets

#### Generic secrets from literals
```bash
$ kubectl create secret generic app-secret \
  --from-literal=username=admin \
  --from-literal=password=secretpassword \
  --from-literal=api_key=abc123xyz789
```

#### From files
```bash
$ echo -n 'admin' > username.txt
$ echo -n 'secretpassword' > password.txt
$ kubectl create secret generic app-secret-file \
  --from-file=username.txt \
  --from-file=password.txt
```

#### Docker registry secrets
```bash
$ kubectl create secret docker-registry regcred \
  --docker-server=myregistry.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
```

#### TLS secrets
```bash
$ kubectl create secret tls tls-secret \
  --cert=path/to/tls.cert \
  --key=path/to/tls.key
```

#### Declaratively with YAML
```bash
$ cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: app-secret-yaml
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded 'admin'
  password: c2VjcmV0cGFzc3dvcmQ=  # base64 encoded 'secretpassword'
stringData:
  api_key: abc123xyz789  # plain text, will be base64 encoded
EOF
```

### Viewing Secrets

```bash
$ kubectl get secrets
$ kubectl describe secret app-secret
$ kubectl get secret app-secret -o yaml
```

Note: `describe` doesn't show secret values, but `-o yaml` shows base64 encoded values.

## Using ConfigMaps and Secrets in Pods

### As Environment Variables

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-config
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-with-config
  template:
    metadata:
      labels:
        app: app-with-config
    spec:
      containers:
      - name: app
        image: nginx:1.21
        env:
        # Single values from ConfigMap
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database_url
        - name: DEBUG_MODE
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: debug_mode
        # Single values from Secret
        - name: USERNAME
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: username
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: password
        # All keys from ConfigMap
        envFrom:
        - configMapRef:
            name: app-config
        # All keys from Secret
        - secretRef:
            name: app-secret
EOF
```

### As Volume Mounts

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-volumes
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-with-volumes
  template:
    metadata:
      labels:
        app: app-with-volumes
    spec:
      containers:
      - name: app
        image: nginx:1.21
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: app-config-yaml
      - name: secret-volume
        secret:
          secretName: app-secret
EOF
```

Check the mounted files:

```bash
$ kubectl exec -it deployment/app-with-volumes -- ls -la /etc/config
$ kubectl exec -it deployment/app-with-volumes -- cat /etc/config/database_url
$ kubectl exec -it deployment/app-with-volumes -- ls -la /etc/secrets
```

### Specific Keys and Paths

You can mount specific keys to specific paths:

```bash
$ cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-selective-mount
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-selective-mount
  template:
    metadata:
      labels:
        app: app-selective-mount
    spec:
      containers:
      - name: app
        image: nginx:1.21
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
      volumes:
      - name: config-volume
        configMap:
          name: app-config-yaml
          items:
          - key: database_url
            path: db.conf
          - key: app.properties
            path: application.properties
EOF
```

## Configuration Updates

### ConfigMap Updates
When you update a ConfigMap, mounted files are updated automatically (with a delay), but environment variables are not updated until the Pod restarts.

```bash
$ kubectl patch configmap app-config -p '{"data":{"debug_mode":"false"}}'
```

### Secret Updates
Similar to ConfigMaps, mounted Secret files are updated automatically, but environment variables require Pod restart.

```bash
$ kubectl patch secret app-secret -p '{"stringData":{"api_key":"new-api-key-xyz"}}'
```

### Force Pod Restart
To pick up environment variable changes:

```bash
$ kubectl rollout restart deployment app-with-config
```

## Immutable ConfigMaps and Secrets

For better performance and to prevent accidental changes, you can make ConfigMaps and Secrets immutable:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: immutable-config
data:
  key: value
immutable: true
```

## Best Practices

### ConfigMaps
1. **Use for non-sensitive data only** - Never put passwords in ConfigMaps
2. **Organize by purpose** - Group related configuration together
3. **Use meaningful names** - Make it clear what the config is for
4. **Version your configs** - Track changes over time
5. **Validate data** - Ensure configuration values are correct

### Secrets
1. **Use for sensitive data** - Passwords, tokens, certificates
2. **Enable encryption at rest** - Configure etcd encryption
3. **Limit access** - Use RBAC to control who can read secrets
4. **Rotate regularly** - Update secrets periodically
5. **Don't log secret values** - Be careful in application logs
6. **Use external secret management** - Consider tools like AWS Secrets Manager

### General
1. **Separate by environment** - Different configs for dev/staging/prod
2. **Use namespaces** - Isolate configurations by team or application
3. **Document your configs** - Make it clear what each setting does
4. **Test configuration changes** - Validate in non-production first
5. **Monitor for changes** - Track when configurations are updated

## Troubleshooting

### ConfigMap/Secret not found
```bash
$ kubectl get configmap <name>
$ kubectl get secret <name>
```

### Environment variables not set
```bash
$ kubectl exec -it <pod-name> -- env | grep <VAR_NAME>
$ kubectl describe pod <pod-name>  # Check for events
```

### Volume mount issues
```bash
$ kubectl exec -it <pod-name> -- ls -la /path/to/mount
$ kubectl describe pod <pod-name>  # Check volume mounts
```

### Permission issues
```bash
$ kubectl auth can-i get configmaps
$ kubectl auth can-i get secrets
```

## Cleanup

Remove all the resources we created:

```bash
$ kubectl delete configmap app-config app-config-file app-config-dir app-config-yaml
$ kubectl delete secret app-secret app-secret-file app-secret-yaml
$ kubectl delete deployment app-with-config app-with-volumes app-selective-mount
```

## What's Next?

Congratulations! You've learned the fundamental concepts of Kubernetes:

- **Concepts** - Understanding the architecture and principles
- **Pods** - The basic unit of deployment
- **Deployments** - Managing application lifecycle
- **Services** - Enabling communication
- **Configuration** - Managing settings and secrets

You're now ready to apply these concepts to a real application in the [Getting Started](../../getting-started) section, where you'll deploy and explore a complete microservices application.