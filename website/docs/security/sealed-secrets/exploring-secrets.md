---
title: "Exploring Secrets"
sidebar_position: 40
---

Run the following command to setup the EKS cluster for this module:

```bash timeout=300 wait=30
$ reset-environment
```

Kubernetes secrets can be exposed to the Pods in different ways such as via environment variables and volumes.

### Exposing Secrets as Environment Variables

You may expose the keys, namely, username and password, in the database-credentials Secret to a Pod as environment variables using a Pod manifest as shown below:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: someName
  namespace: someNamespace
spec:
  containers:
  - name: someContainer
    image: someImage
    env:
    - name: DATABASE_USER
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: username
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: database-credentials
          key: password
```

### Exposing Secrets as Volumes

Secrets can also be mounted as data volumes on to a Pod and you can control the paths within the volume where the Secret keys are projected using a Pod manifest as shown below:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: someName
  namespace: someNamespace
spec:
  containers:
  - name: someContainer
    image: someImage
    volumeMounts:
    - name: secret-volume
      mountPath: "/etc/data"
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: database-credentials
      items:
      - key: username
        path: DATABASE_USER 
      - key: password
        path: DATABASE_PASSWORD

```

With the above Pod specification, the following will occur:

* value for the username key in the database-credentials Secret is stored in the file `/etc/data/DATABASE_USER` within the Pod
* value for the password key is stored in the file `/etc/data/DATABASE_PASSWORD`

### Exploring the catalog Pod

The catalog deployment in the catalog Namespace accesses the following database values from the `catalog-db` secret via environment variables:

* `DB_ENDPOINT`
* `DB_USER`
* `DB_PASSWORD`
* `DB_NAME`

```yaml
- name: DB_ENDPOINT
  valueFrom:
    secretKeyRef:
      name: catalog-db
      key: endpoint
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: catalog-db
      key: username
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: catalog-db
      key: password
- name: DB_NAME
  valueFrom:
    secretKeyRef:
      name: catalog-db
      key: name
```

Upon exploring the `catalog-db` Secret we can see that it is only encoded with base64 which can be easily decoded as follows hence making it difficult for the secrets manifests to be part of the GitOps workflow.

```file
../manifests/catalog/secrets.yaml
```

```bash
$ echo "Y2F0YWxvZ191c2Vy" | base64 -d
catalog_user%
$ echo "ZGVmYXVsdF9wYXNzd29yZA==" | base64 -d
default_password%   
```