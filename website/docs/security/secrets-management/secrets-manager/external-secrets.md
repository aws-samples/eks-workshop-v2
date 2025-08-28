---
title: "External Secrets Operator"
sidebar_position: 424
---

Now let's explore integrating with AWS Secrets Manager using the External Secrets operator. This has already been installed in our EKS cluster:

```bash
$ kubectl -n external-secrets get pods
NAME                                                READY   STATUS    RESTARTS   AGE
external-secrets-6d95d66dc8-5trlv                   1/1     Running   0          7m
external-secrets-cert-controller-774dff987b-krnp7   1/1     Running   0          7m
external-secrets-webhook-6565844f8f-jxst8           1/1     Running   0          7m
$ kubectl -n external-secrets get sa
NAME                  SECRETS   AGE
default               0         7m
external-secrets-sa   0         7m
```

The operator uses a ServiceAccount named `external-secrets-sa` which is tied to an IAM role via [IRSA](../../iam-roles-for-service-accounts/), providing access to AWS Secrets Manager for retrieving secrets:

```bash
$ kubectl -n external-secrets describe sa external-secrets-sa | grep Annotations
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::1234567890:role/eks-workshop-external-secrets-sa-irsa
```

We need to create a `ClusterSecretStore` resource - this is a cluster-wide SecretStore that can be referenced by ExternalSecrets from any namespace. Lets inspect the file we will use to create this `ClusterSecretStore`:

::yaml{file="manifests/modules/security/secrets-manager/cluster-secret-store.yaml" paths="spec.provider.aws.service,spec.provider.aws.region,spec.provider.aws.auth.jwt"}

1. Set `service: SecretsManager` to use AWS Secrets Manager as the secret source
2. Use the `$AWS_REGION` environment variable to specify the AWS region where secrets are stored
3. `auth.jwt` uses IRSA to authenticate via the `external-secrets-sa` service account in the `external-secrets` namespace, which is linked to an IAM role with AWS Secrets Manager permissions

Lets use this file to create the ClusterSecretStore resource.

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/cluster-secret-store.yaml \
  | envsubst | kubectl apply -f -
```

Next, we'll create an `ExternalSecret` that defines what data should be fetched from AWS Secrets Manager and how it should be transformed into a Kubernetes Secret. We'll then update our `catalog` Deployment to use these credentials:

```kustomization
modules/security/secrets-manager/external-secrets/kustomization.yaml
Deployment/catalog
ExternalSecret/catalog-external-secret
```

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/security/secrets-manager/external-secrets/ \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n catalog deployment/catalog --timeout=120s
```

Let's examine our new `ExternalSecret` resource:

```bash
$ kubectl -n catalog get externalsecrets.external-secrets.io
NAME                      STORE                  REFRESH INTERVAL   STATUS         READY
catalog-external-secret   cluster-secret-store   1h                 SecretSynced   True
```

The `SecretSynced` status indicates successful synchronization from AWS Secrets Manager. Let's look at the resource specifications:

```bash
$ kubectl -n catalog get externalsecrets.external-secrets.io catalog-external-secret -o yaml | yq '.spec'
dataFrom:
  - extract:
      conversionStrategy: Default
      decodingStrategy: None
      key: eks-workshop-catalog-secret-WDD8yS
refreshInterval: 1h
secretStoreRef:
  kind: ClusterSecretStore
  name: cluster-secret-store
target:
  creationPolicy: Owner
  deletionPolicy: Retain
```

The configuration references our AWS Secrets Manager secret via the `key` parameter and the `ClusterSecretStore` we created earlier. The `refreshInterval` of 1 hour determines how often the secret values are synchronized.

When we create an ExternalSecret, it automatically creates a corresponding Kubernetes secret:

```bash
$ kubectl -n catalog get secrets
NAME                      TYPE     DATA   AGE
catalog-db                Opaque   2      21h
catalog-external-secret   Opaque   2      1m
catalog-secret            Opaque   2      5h40m
```

This secret is owned by the External Secrets Operator:

```bash
$ kubectl -n catalog get secret catalog-external-secret -o yaml | yq '.metadata.ownerReferences'
- apiVersion: external-secrets.io/v1beta1
  blockOwnerDeletion: true
  controller: true
  kind: ExternalSecret
  name: catalog-external-secret
  uid: b8710001-366c-44c2-8e8d-462d85b1b8d7
```

We can verify our `catalog` pod is using the new secret values:

```bash
$ kubectl -n catalog get pods
NAME                       READY   STATUS    RESTARTS   AGE
catalog-777c4d5dc8-lmf6v   1/1     Running   0          1m
catalog-mysql-0            1/1     Running   0          24h
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .env'
- name: RETAIL_CATALOG_PERSISTENCE_USER
  valueFrom:
    secretKeyRef:
      key: username
      name: catalog-external-secret
- name: RETAIL_CATALOG_PERSISTENCE_PASSWORD
  valueFrom:
    secretKeyRef:
      key: password
      name: catalog-external-secret
```

### Conclusion

There is no single "best" choice between **AWS Secrets and Configuration Provider (ASCP)** and **External Secrets Operator (ESO)** for managing AWS Secrets Manager secrets.

Each tool has distinct advantages:

- **ASCP** can mount secrets directly from AWS Secrets Manager as volumes, avoiding exposure as environment variables, though this requires volume management.

- **ESO** simplifies Kubernetes Secrets lifecycle management and offers cluster-wide SecretStore capability, but doesn't support volume mounting.

Your specific use case should drive the decision, and using both tools can provide maximum flexibility and security in secrets management.
