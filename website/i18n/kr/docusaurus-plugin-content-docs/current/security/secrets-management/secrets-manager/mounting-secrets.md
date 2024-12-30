---
title: "Mounting AWS Secrets Manager secret on Kubernetes Pod"
sidebar_position: 423
---

Now that we have a secret stored in AWS Secrets Manager and synchronized with a Kubernetes Secret, let's mount it inside the Pod. First, we should examine the `catalog` Deployment and the existing Secrets in the `catalog` namespace.

Currently, the `catalog` Deployment accesses database credentials from the `catalog-db` secret via environment variables:

- `DB_USER`
- `DB_PASSWORD`

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .env'

- name: DB_USER
  valueFrom:
    secretKeyRef:
      key: username
      name: catalog-db
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      key: password
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

The Deployment now has a new `volume` and corresponding `volumeMount` that uses the CSI Secret Store Driver and is mounted at `/etc/catalog-secrets`:

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
{"username":"catalog_user", "password":"default_password"}
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/username
catalog_user
$ kubectl -n catalog exec deployment/catalog -- cat /etc/catalog-secret/password
default_password
```

The mountPath `/etc/catalog-secret` contains three files:

1. `eks-workshop-catalog-secret`: Contains the complete secret value in JSON format
2. `password`: Contains the password value filtered by jmesPath
3. `username`: Contains the username value filtered by jmesPath

The environment variables are now sourced from the newly created `catalog-secret`, which was automatically created by the SecretProviderClass via the CSI Secret Store driver:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .env'
- name: DB_USER
  valueFrom:
    secretKeyRef:
      key: username
      name: catalog-secret
- name: DB_PASSWORD
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
$ kubectl -n catalog exec -ti deployment/catalog -- env | grep DB_
```

We now have a Kubernetes Secret fully integrated with AWS Secrets Manager that can leverage secret rotation, a best practice for secrets management. When a secret is rotated or updated in AWS Secrets Manager, we can roll out a new version of the Deployment allowing the CSI Secret Store driver to synchronize the Kubernetes Secret contents with the updated value.
