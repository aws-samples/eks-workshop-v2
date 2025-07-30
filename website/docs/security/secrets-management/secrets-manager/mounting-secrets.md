---
title: "Mounting AWS Secrets Manager secret on Kubernetes Pod"
sidebar_position: 423
---

Now that we have a secret stored in AWS Secrets Manager and synchronized with a Kubernetes Secret, let's mount it inside the Pod. First, we should examine the `catalog` Deployment and the existing Secrets in the `catalog` namespace.

Currently, the `catalog` Deployment accesses database credentials from the `catalog-db` secret via environment variables:

- `RETAIL_CATALOG_PERSISTENCE_USER`
- `RETAIL_CATALOG_PERSISTENCE_PASSWORD`

This is done by referencing a Secret with `envFrom`:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .envFrom'

- configMapRef:
    name: catalog
- secretRef:
    name: catalog-db
```

The `catalog` Deployment currently has no additional `volumes` or `volumeMounts` except for an `emptyDir` mounted at `/tmp`:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.volumes'
- emptyDir:
    medium: Memory
  name: tmp-volume
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .volumeMounts'
- mountPath: /tmp
  name: tmp-volume
```

Let's modify the `catalog` Deployment to use the secret stored in AWS Secrets Manager as the source for credentials:

```kustomization
modules/security/secrets-manager/mounting-secrets/kustomization.yaml
Deployment/catalog
```

We'll mount the AWS Secrets Manager secret using the CSI driver with the SecretProviderClass we validated earlier at the `/etc/catalog-secret` mountPath inside the Pod. This will trigger AWS Secrets Manager to synchronize the stored secret contents with Amazon EKS and create a Kubernetes Secret that can be consumed as environment variables in the Pod.

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/security/secrets-manager/mounting-secrets/ \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n catalog deployment/catalog --timeout=120s
```

Let's verify the changes made in the `catalog` namespace.

The Deployment now has a new `volume` and corresponding `volumeMount` that uses the CSI Secret Store Driver and is mounted at `/etc/catalog-secret`:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.volumes'
- csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: catalog-spc
  name: catalog-secret
- emptyDir:
    medium: Memory
  name: tmp-volume
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .volumeMounts'
- mountPath: /etc/catalog-secret
  name: catalog-secret
  readOnly: true
- mountPath: /tmp
  name: tmp-volume
```

Mounted Secrets provide a secure way to access sensitive information as files inside the Pod's container filesystem. This approach offers several benefits including not exposing secret values as environment variables and automatic updates when the source Secret is modified.

Let's examine the contents of the mounted Secret inside the Pod:

```bash
$ kubectl -n catalog exec deployment/catalog -- ls /etc/catalog-secret/
eks-workshop-catalog-secret  password  username
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/${SECRET_NAME}
{"username":"catalog", "password":"dYmNfWV4uEvTzoFu"}
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/username
catalog
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/password
dYmNfWV4uEvTzoFu
```

:::info
When mounting secrets from AWS Secrets Manager using the CSI driver, three files are created in the mountPath:

1. A file with the name of your AWS secret containing the complete JSON value
2. Individual files for each key extracted via jmesPath expressions as defined in the SecretProviderClass
   :::

The environment variables are now sourced from the newly created `catalog-secret`, which was automatically created by the SecretProviderClass via the CSI Secret Store driver:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .env'
- name: RETAIL_CATALOG_PERSISTENCE_USER
  valueFrom:
    secretKeyRef:
      key: username
      name: catalog-secret
- name: RETAIL_CATALOG_PERSISTENCE_PASSWORD
  valueFrom:
    secretKeyRef:
      key: password
      name: catalog-secret
$ kubectl -n catalog get secrets
NAME             TYPE     DATA   AGE
catalog-db       Opaque   2      15h
catalog-secret   Opaque   2      43s
```

We can confirm the environment variables are set correctly in the running pod:

```bash
$ kubectl -n catalog exec -ti deployment/catalog -- env | grep PERSISTENCE
RETAIL_CATALOG_PERSISTENCE_USER=catalog
RETAIL_CATALOG_PERSISTENCE_PASSWORD=dYmNfWV4uEvTzoFu
```

We now have a Kubernetes Secret fully integrated with AWS Secrets Manager that can leverage secret rotation, a best practice for secrets management. When a secret is rotated or updated in AWS Secrets Manager, we can roll out a new version of the Deployment allowing the CSI Secret Store driver to synchronize the Kubernetes Secret contents with the updated value.
