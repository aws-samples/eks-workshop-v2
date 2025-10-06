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

::yaml{file="manifests/base-application/catalog/secrets.yaml" paths="kind,metadata.name,data" title="catalog-secret.yaml"}

1. `kind: Secret`: Tells Kubernetes what type of resource to create
2. `metadata.name`: Unique identifier for this Secret within the namespace
5. `data`: Key-value pairs containing sensitive data (base64 encoded)

Apply the Secret configuration:
```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/introduction/basics/secrets
```

### Exploring Your Secret

Now let's examine the Secret we just created:

```bash
$ kubectl get secrets -n catalog
NAME         TYPE     DATA   AGE
catalog-db   Opaque   2      30s
```

Get detailed information about the Secret:
```bash
$ kubectl describe secret -n catalog catalog-db
Name:         catalog-db
Namespace:    catalog
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
RETAIL_CATALOG_PERSISTENCE_PASSWORD:  16 bytes
RETAIL_CATALOG_PERSISTENCE_USER:      7 bytes
```

This shows:
- **Type** - The kind of secret (Opaque for general use)
- **Data** - Number of key-value pairs (values are hidden for security)
- **Labels** - Metadata tags for organization

Notice that the actual values are not displayed for security reasons. To see the base64 encoded data:
```bash
$ kubectl get secret catalog-db -n catalog -o yaml
apiVersion: v1
data:
  RETAIL_CATALOG_PERSISTENCE_PASSWORD: ZFltTmZXVjR1RXZUem9GdQ==
  RETAIL_CATALOG_PERSISTENCE_USER: Y2F0YWxvZw==
kind: Secret
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"RETAIL_CATALOG_PERSISTENCE_PASSWORD":"ZFltTmZXVjR1RXZUem9GdQ==","RETAIL_CATALOG_PERSISTENCE_USER":"Y2F0YWxvZw=="},"kind":"Secret","metadata":{"annotations":{},"name":"catalog-db","namespace":"catalog"}}
  creationTimestamp: "2025-10-05T17:52:34Z"
  name: catalog-db
  namespace: catalog
  resourceVersion: "902820"
  uid: 726e4fef-f82b-4a7e-a063-f72f18a941cd
type: Opaque
```

You'll see the data is base64 encoded. To decode a value:
```bash
$ kubectl get secret catalog-db -n catalog -o jsonpath='{.data.RETAIL_CATALOG_PERSISTENCE_USER}' | base64 --decode
catalog
```

### Using Secrets in Pods

Now let's create a pod that uses our Secret. We'll update our catalog pod to use the database credentials:

::yaml{file="manifests/modules/introduction/basics/secrets/catalog-pod-with-secret.yaml" paths="kind,metadata.name,spec.containers,spec.containers.0.envFrom" title="catalog-pod-with-secret.yaml"}

The key differences here are:
- `envFrom.configMapRef`: Loads all key-value pairs from a ConfigMap as environment variables
- `envFrom.secretRef`: Loads all key-value pairs from a Secret as environment variables
- This approach automatically makes all Secret data available without mapping individual keys

Apply the updated pod configuration:
```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/introduction/basics/secrets/catalog-pod-with-secret.yaml
```

### Testing the Secret Access

Let's verify that our pod can access the secret values:

```bash hook=ready
$ kubectl exec -n catalog catalog-pod -- env | grep RETAIL_CATALOG_PERSISTENCE_USER
RETAIL_CATALOG_PERSISTENCE_USER=catalog_user
```

You can also see all catalog-related environment variables:
```bash
$ kubectl exec -n catalog catalog-pod -- env | grep RETAIL_CATALOG
RETAIL_CATALOG_PERSISTENCE_PROVIDER=mysql
RETAIL_CATALOG_PERSISTENCE_ENDPOINT=catalog-mysql:3306
RETAIL_CATALOG_PERSISTENCE_DB_NAME=catalog
RETAIL_CATALOG_PERSISTENCE_USER=catalog_user
RETAIL_CATALOG_PERSISTENCE_PASSWORD=dYmNfWV4uEvTzoFu
```

:::warning
In production, avoid printing passwords to logs or console output. This is shown here for educational purposes only.
:::

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

