
---
title: "AWS Secrets and Configuration Provider (ASCP)"
sidebar_position: 422
---

The `prepare-environment` script we ran in the [previous step](./index.md) has already installed the AWS Secrets and Configuration Provider (ASCP) for the Kubernetes Secrets Store CSI Driver required for this lab.

Let's validate that the addons were deployed correctly.

First, check the Secret Store CSI driver `DaemonSet` and its `Pods`:

```bash
$ kubectl -n kube-system get pods,daemonsets -l app=secrets-store-csi-driver
NAME                                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/csi-secrets-store-secrets-store-csi-driver   3         3         3       3            3           kubernetes.io/os=linux   3m57s

NAME                                                   READY   STATUS    RESTARTS   AGE
pod/csi-secrets-store-secrets-store-csi-driver-bzddm   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-k7m6c   3/3     Running   0          3m57s
pod/csi-secrets-store-secrets-store-csi-driver-x2rs4   3/3     Running   0          3m57s
```

Next, check the CSI Secrets Store Provider for AWS driver `DaemonSet` and its `Pods`:

```bash
$ kubectl -n kube-system get pods,daemonset -l "app=secrets-store-csi-driver-provider-aws"
NAME                                                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/secrets-store-csi-driver-provider-aws   3         3         3       3            3           kubernetes.io/os=linux   2m3s

NAME                                              READY   STATUS    RESTARTS   AGE
pod/secrets-store-csi-driver-provider-aws-4jf8f   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-djtf5   1/1     Running   0          2m2s
pod/secrets-store-csi-driver-provider-aws-dzg9r   1/1     Running   0          2m2s
```

To provide access to secrets stored in AWS Secrets Manager via the CSI driver, we need a `SecretProviderClass` - a namespaced custom resource that provides driver configurations and specific parameters matching the information in AWS Secrets Manager.

```file
manifests/modules/security/secrets-manager/secret-provider-class.yaml
```

Let's create this resource and examine its configuration:

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/secret-provider-class.yaml \
  | envsubst | kubectl apply -f -
```

The `SecretProviderClass` has two main configuration sections. First, the `objects` parameter points to the secret we created in AWS Secrets Manager. Note that we're using [jmesPath](https://jmespath.org/) to extract specific key-value pairs from the JSON-formatted secret:

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

Second, the `secretObjects` section defines how to create and sync a Kubernetes Secret with data from the AWS Secrets Manager secret:

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

When mounted to a Pod, the SecretProviderClass will create a Kubernetes Secret (if it doesn't exist) named `catalog-secret` and sync the values from AWS Secrets Manager. This establishes the connection between our AWS secret and the Kubernetes environment.
