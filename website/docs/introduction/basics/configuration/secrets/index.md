---
title: Secrets
sidebar_position: 20
sidebar_custom_props: { "module": true }
---

# Secrets

::required-time

:::tip Before you start
Prepare your environment for this section:

```bash timeout=300 wait=10
$ prepare-environment introduction/basics/secrets
```

:::

**Secrets** are used to store and manage sensitive information such as passwords, OAuth tokens, SSH keys, and TLS certificates. They provide a more secure way to handle confidential data compared to putting it directly in pod specifications or container images.

Secrets provide:
- **Security:** Store sensitive data separately from application code
- **Access Control:** Control which pods and users can access sensitive information
- **Encryption:** Data is base64 encoded and can be encrypted at rest
- **Flexibility:** Use secrets as environment variables, files, or for image pulls

In this lab, you'll learn about Secrets by creating database credentials for our retail store's catalog service and seeing how pods securely access this sensitive information.

### Creating Your First Secret

Let's create a Secret for our retail store's catalog service. The catalog needs database credentials to connect to its MySQL database:

::yaml{file="manifests/modules/introduction/basics/secrets/catalog-secret.yaml" paths="kind,metadata.name,metadata.namespace,type,stringData" title="catalog-secret.yaml"}

1. `kind: Secret`: Tells Kubernetes what type of resource to create
2. `metadata.name`: Unique identifier for this Secret within the namespace
3. `metadata.namespace`: Which namespace the Secret belongs to (catalog namespace)
4. `type: Opaque`: The default type for arbitrary user-defined data
5. `stringData`: Key-value pairs containing sensitive data (automatically base64 encoded)

Apply the Secret configuration:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/secrets/catalog-secret.yaml
```

### Exploring Your Secret

Now let's examine the Secret we just created:

```bash
$ kubectl get secrets -n catalog
```

You should see output like:
```
NAME         TYPE     DATA   AGE
catalog-db   Opaque   2      30s
```

Get detailed information about the Secret:
```bash
$ kubectl describe secret -n catalog catalog-db
```

This shows:
- **Type** - The kind of secret (Opaque for general use)
- **Data** - Number of key-value pairs (values are hidden for security)
- **Labels** - Metadata tags for organization

Notice that the actual values are not displayed for security reasons. To see the base64 encoded data:
```bash
$ kubectl get secret catalog-db -n catalog -o yaml
```

You'll see the data is base64 encoded. To decode a value:
```bash
$ kubectl get secret catalog-db -n catalog -o jsonpath='{.data.username}' | base64 --decode
```

### Using Secrets in Pods

Now let's create a pod that uses our Secret. We'll update our catalog pod to use the database credentials:

::yaml{file="manifests/modules/introduction/basics/secrets/catalog-pod-with-secret.yaml" paths="kind,metadata.name,spec.containers,spec.containers.0.env,spec.containers.0.env.0.valueFrom.secretKeyRef" title="catalog-pod-with-secret.yaml"}

The key difference here is:
- `env.valueFrom.secretKeyRef`: References a specific key from a Secret
- `secretKeyRef.name`: The name of the Secret to reference
- `secretKeyRef.key`: The specific key within the Secret

Apply the updated pod configuration:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/secrets/catalog-pod-with-secret.yaml
```

### Testing the Secret Access

Let's verify that our pod can access the secret values:

```bash
$ kubectl exec -n catalog catalog-pod -- env | grep DB_USERNAME
```

You should see:
```
DB_USERNAME=catalog-user
```

The password is also available but won't be shown in logs for security:
```bash
$ kubectl exec -n catalog catalog-pod -- printenv DB_PASSWORD
```

Now let's test if the catalog service can connect to its database:
```bash
$ kubectl port-forward -n catalog catalog-pod 8080:8080 &
```

Test the catalog API:
```bash
$ curl localhost:8080/catalogue
```

You should see JSON data with product information, indicating the catalog service successfully connected to the database using the credentials from our Secret!

Stop the port-forward:
```bash
$ pkill -f "kubectl port-forward"
```

## Secrets vs ConfigMaps

| Secrets | ConfigMaps |
|---------|------------|
| Sensitive data (passwords, tokens) | Non-confidential data |
| Base64 encoded + additional security | Base64 encoded for storage |
| Values hidden in kubectl output | Visible in plain text |
| Credentials, certificates, keys | Configuration files, environment variables |

## Advanced Secrets Management

While Kubernetes Secrets provide basic security for sensitive data, production environments often require more sophisticated secrets management solutions. For enhanced security features like automatic rotation, fine-grained access control, and integration with external secret stores, explore:

**[AWS Secrets Manager Integration](../../../security/secrets-management/secrets-manager/)** - Learn how to integrate AWS Secrets Manager with your EKS cluster for enterprise-grade secrets management with automatic rotation and centralized control.

## Key Points to Remember

* Secrets store sensitive data separately from application code
* Values are base64 encoded and can be encrypted at rest
* Secret values are hidden in kubectl describe output for security
* Can be consumed as environment variables or mounted as files
* Use ConfigMaps for non-sensitive configuration data
* For production workloads, consider advanced solutions like AWS Secrets Manager

