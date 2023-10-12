---
title: "Mounting AWS Secrets Manager secret on Kubernetes Pod"
sidebar_position: 63
---

Now that we have our secret stored in AWS Secrets Manager, let's mount it inside our Pod, but first we should take a look on the `catalog` Deployment and the existing Secrets in the `catalog` Namespace.

The `catalog` Deployment accesses the following database credentials from the `catalog-db` secret via environment variables:

* `DB_USER`
* `DB_PASSWORD`

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

If we take a closer look to the `catalog-db` Secret we can see that it is only encoded with *base64* which can be easily decoded as follows. Also the `catalog-db` is the only Secret in the Namespace.

```file
manifests/base-application/catalog/secrets.yaml
```

```bash
$ kubectl -n catalog get secrets
NAME             TYPE     DATA   AGE
catalog-db       Opaque   2      15h
$ kubectl -n catalog get secrets catalog-db --template {{.data.username}} | base64 -d
catalog_user                                                                                                                                                                                                
$ kubectl -n catalog get secrets catalog-db --template {{.data.password}} | base64 -d
default_password
```

Notice that the `catalog` Deployment don't have any `volumes` or `volumeMounts` other than an `emptyDir` mounted on `/tmp`

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.volumes'
- emptyDir:
    medium: Memory
  name: tmp-volume

$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .volumeMounts'
- mountPath: /tmp
  name: tmp-volume
```

Let's go and apply the changes in the `catalog` Deployment to use the secret stored in AWS Secrets Manager as the source of our credentials.

```kustomization
manifests/modules/security/secrets-manager/mounting-secrets/kustomization.yaml
Deployment/catalog
```

Here we will be mounting the AWS Secrets Manager secret using the CSI driver with the SecretProviderClass we validated earlier on the `/etc/catalog-secret` mountPath inside the Pod. When this happens, AWS Secrets Manager will sync the content of the stored secret with Amazon EKS, and create a Kubernetes Secret with the same contents that can be consumed as Environment variables in the Pod.

```
$ kubectl apply -k ~/environment/eks-workshop/modules/security/secrets-manager/mounting-secrets/
```

Let's validate the changes made in the `catalog` Namespace.

In the Deployment, youll' be able to check that it has a new `volume` and respective `volumeMount` pointing to our CSI Secret Store Driver, and mounted on `/etc/catalog-secrets` path.

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

Also, the Environment Variables are now being consumed from a new Secret, called `catalog-secret` that didn't exist earlier, and it was created by the SecretProviderClass via CSI Secret Store driver.

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

Now we have a Kubernetes Secrets fully integrated with AWS Secrets Manager, that can leverage secrets rotation which is a best practice for Secrets Management. So everytime a secret is rotated or updated on AWS Secrets Manager, you'll just need to rollout a new version of your Deployment for the CSI Secret Store driver can sync the Kubernetes Secrets contents.
