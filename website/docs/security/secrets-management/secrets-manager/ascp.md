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

To provide access to secrets stored in AWS Secrets Manager via the CSI driver, you'll need a `SecretProviderClass` - a namespaced custom resource that provides driver configurations and parameters matching the information in AWS Secrets Manager.

::yaml{file="manifests/modules/security/secrets-manager/secret-provider-class.yaml" paths="spec.provider,spec.parameters.objects,spec.secretObjects.0"}

1. `provider: aws` specifies AWS Secrets Store CSI driver
2. `parameters.objects` defines the AWS `secretsmanager` source secret named `$SECRET_NAME` and uses [jmesPath](https://jmespath.org/) to extract specific `username` and `password` fields into named aliases for Kubernetes consumption
3. `secretObjects` creates a standard `Opaque` Kubernetes secret named `catalog-secret` that maps the extracted `username` and `password` fields to secret keys

Let's create this resource:

```bash
$ cat ~/environment/eks-workshop/modules/security/secrets-manager/secret-provider-class.yaml \
  | envsubst | kubectl apply -f -
```

The Secret Store CSI Driver acts as an intermediary between Kubernetes and external secrets providers like AWS Secrets Manager. When configured with a SecretProviderClass, it can both mount secrets as files in Pod volumes and create synchronized Kubernetes Secret objects, providing flexibility in how applications consume these secrets.
