---
title: "Mounting AWS Secrets Manager secret on Kubernetes Pod"
sidebar_position: 423
---

Now that we have a secret stored in AWS Secrets Manager and synchronized with a Kubernetes Secret let's mount it inside the Pod. First we should take a look at the `catalog` Deployment and the existing Secrets in the `catalog` namespace.

The `catalog` Deployment accesses the following database credentials from the `catalog-db` secret via environment variables:

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

Notice that the `catalog` Deployment doesn't have any `volumes` or `volumeMounts` other than an `emptyDir` mounted on `/tmp`

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.volumes'
- emptyDir:
    medium: Memory
  name: tmp-volume
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .volumeMounts'
- mountPath: /tmp
  name: tmp-volume
```

Let's go and apply the changes in the `catalog` Deployment to use the secret stored in AWS Secrets Manager as the source of the credentials.

```kustomization
modules/security/secrets-manager/mounting-secrets/kustomization.yaml
Deployment/catalog
```

Here we will be mounting the AWS Secrets Manager secret using the CSI driver with the SecretProviderClass we validated earlier on the `/etc/catalog-secret` mountPath inside the Pod. When this happens, AWS Secrets Manager will sync the contents of the stored secret with Amazon EKS, and create a Kubernetes Secret with the same contents that can be consumed as environment variables in the Pod.

```bash
$ kubectl kustomize ~/environment/eks-workshop/modules/security/secrets-manager/mounting-secrets/ \
  | envsubst | kubectl apply -f-
$ kubectl rollout status -n catalog deployment/catalog --timeout=120s
```

Let's validate the changes made in the `catalog` Namespace.

In the Deployment, we'll be able to check that it has a new `volume` and respective `volumeMount` pointing to the CSI Secret Store Driver, and mounted on `/etc/catalog-secrets` path.

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

Mounted Secrets are a good way to have sensitive information available as a file inside the filesystem of one or more of the Pod's containers. Some benefits are not exposing the value of the secret as environment variables and when a volume contains data from a Secret, and when that Secret is updated Kubernetes tracks it and updates the data in the volume.

You can take a look on the contents of the mounted Secret inside your Pod.

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

There are 3 files in the mountPath `/etc/catalog-secret`. `

1. `eks-workshop-catalog-secret`: The value of the secret in JSON format.
2. `password`: password jmesPath filtered and formatted value.
3. `username`: username jmesPath filtered and formatted value.

Also, the environment variables are now being consumed from the new Secret, `catalog-secret` that didn't exist earlier, and it was created by the SecretProviderClass via CSI Secret Store driver.

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

We can verify this by checking the environment variables in the running pod:

```bash
$ kubectl -n catalog exec -ti deployment/catalog -- env | grep DB_
```

Now we have a Kubernetes Secret fully integrated with AWS Secrets Manager that can leverage secret rotation, which is a best practice for Secrets Management. Everytime a secret is rotated or updated on AWS Secrets Manager, we can roll out a new version of your Deployment so the CSI Secret Store driver can sync the Kubernetes Secrets contents with the rotated value.
