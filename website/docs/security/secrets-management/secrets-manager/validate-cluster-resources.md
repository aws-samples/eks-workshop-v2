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

You should also see that we already have created a SecretProviderClass, which is a namespaced custom resource that's used provide driver configurations and specific parameters to access your secrets stored in AWS Secrets Manger via CSI driver.

```file
manifests/modules/security/secrets-manager/secret-provider-class.yaml
```

In the above resource, we have two main configurations that we should be focusing.

The *objects* parameter, which is pointing to a secret named as `eks-workshop/catalog-secret` that we will store in AWS Secrets Manager in the next step. Note that we are using [jmesPath](https://jmespath.org/), to extract a specific key-value from the secret that is JSON-formatted.

```bash
$ kubectl get secretproviderclass -n catalog catalog-spc -o yaml | yq '.spec.parameters.objects'

- objectName: "eks-workshop/catalog-secret"
  objectType: "secretsmanager"
  jmesPath:
    - path: username
      objectAlias: username
    - path: password
      objectAlias: password
```

And the *secretObjects*, that will create and/or sync a Kubernetes secret with the data from the secret stored in AWS Secrets Manager. This means that when mounted to a Pod, the SecretProviderClass, will create a Kubernetes Secret, if it doesn't exist yet, and sync the values stored in AWS Secrets Manager with this Kubernetes Secret, in our case, it will be called as `catalog-secret`.

```bash
$ kubectl get secretproviderclass -n catalog catalog-spc -o yaml | yq '.spec.secretObjects'

- data:
    - key: username
      objectName: username
    - key: password
      objectName: password
  secretName: catalog-secret
  type: Opaque
```

Lets move on, and store our credentials on AWS Secrets Manager.
