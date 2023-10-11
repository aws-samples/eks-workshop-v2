---
title: "Validating AWS Secrets and Configuration Provider (ASCP)"
sidebar_position: 61
---

If you ran the `prepare-environment` script detailed in the [previous step](./index.md), it has already installed the AWS Secrets and Configuration Provider (ASCP) for the Kubernetes Secrets Store CSI Driver that's required for this lab.

Lets then, validate if the addons deployed.

Check the Secret Store CSI drive `DaemonSet` and respective `Pods`.

```bash
$ kubectl -n secrets-store-csi-driver get pods,daemonsets -l app=secrets-store-csi-driver
NAME                                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/csi-secrets-store-secrets-store-csi-driver   3         3         3       3            3           kubernetes.io/os=linux   3m57s

NAME                                                   READY   STATUS    RESTARTS   AGE
pod/csi-secrets-store-secrets-store-csi-driver-bzddm   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-k7m6c   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-x2rs4   3/3     Running   0          3m57s
```

Check the CSI Secrets Store Provider for AWS driver `DaemonSet` and respective `Pods`.

```bash
$ kubectl -n kube-system get pods,daemonset -l "app=secrets-store-csi-driver-provider-aws"  
NAME                                                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/secrets-store-csi-driver-provider-aws   3         3         3       3            3           kubernetes.io/os=linux   2m3s

NAME                                              READY   STATUS    RESTARTS   AGE
pod/secrets-store-csi-driver-provider-aws-4jf8f   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-djtf5   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-dzg9r   1/1     Running   0          2m2s
```

### Exploring the catalog Pod

The `catalog` deployment in the `catalog` Namespace accesses the following database values from the catalog-db secret via environment variables:

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
- name: DB_NAME
  valueFrom:
    configMapKeyRef:
      key: name
      name: catalog
- name: DB_READ_ENDPOINT
  valueFrom:
    secretKeyRef:
      key: endpoint
      name: catalog-db
- name: DB_ENDPOINT
  valueFrom:
    secretKeyRef:
      key: endpoint
      name: catalog-db
```

Upon exploring the `catalog-db` Secret we can see that it is only encoded with base64 which can be easily decoded as follows hence making it difficult for the secrets manifests to be part of the GitOps workflow.

```file
manifests/base-application/catalog/secrets.yaml
```

```bash
$ kubectl -n catalog get secrets catalog-db --template {{.data.username}} | base64 -d
catalog_user%                                                                                                                                                                                                   
$ kubectl -n catalog get secrets catalog-db --template {{.data.password}} | base64 -d
default_password% 
```

You should also see that we already have created a *SecretProviderClass*, which is a namespaced custom resource that's used provide driver configurations and specific parameters to the your secrets in AWS Secrets Manger via CSI driver.

```bash
$ kubectl -n catalog get secretproviderclass -o yaml

apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: catalog-spc
  namespace: catalog
spec:
  provider: aws
  parameters:
    objects: |
        - objectName: "catalog-secret"
          objectType: "secretsmanager"
```
