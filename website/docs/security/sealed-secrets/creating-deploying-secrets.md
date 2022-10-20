---
title: "Creating and Deploying Secrets"
sidebar_position: 40
---

Run the following command to setup the EKS cluster for this module:

```bash timeout=300 wait=30
$ reset-environment
```
Kubectl supports the management of Kubernetes objects using Kustomize. [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/#overview-of-kustomize) provides resource generators to create Secrets and ConfigMaps. The Kustomize generators should be specified in a kustomization.yaml file. A Kustomize file for generating a Secret from literal key-value pairs looks as follows:

```file
security/sealed-secrets/kustomization.yaml
```

Let's create a new namespace `secure-secrets` and deploy the secret in your EKS cluster

```bash timeout=180
$ kubectl create ns secure-secrets
$ kubectl apply -k /workspace/modules/security/sealed-secrets
```

### Exposing Secrets as Environment Variables

You may expose the keys, namely, username and password, in the database-credentials Secret to a Pod as environment variables using a Pod manifest as shown below:

```file
security/sealed-secrets/sample-secret-env-pod.yaml
```

Run the following set of commands to deploy a pod that references the **database-credentials** Secret created above.

```bash
$ kubectl apply -f /workspace/modules/security/sealed-secrets/pod-variable.yaml
$ kubectl get pod -n secure-secrets
```

View the output logs from the pod to verfiy that the environment variables `DATABASE_USER` and `DATABASE_PASSWORD` have been assigned the expected literal values.

```bash test=false
$ kubectl logs pod-variable -n secure-secrets

DATABASE_USER = admin
DATABASE_PASSWROD = Tru5tN0!
```

### Exposing Secrets as Volumes

Secrets can also be mounted as data volumes on to a Pod and you can control the paths within the volume where the Secret keys are projected using a Pod manifest as shown below:

```file
security/sealed-secrets/sample-secret-volumes-pod.yaml
```

With the above pod specification, the following will occur:

* value for the username key in the database-credentials Secret is stored in the file /etc/data/DATABASE_USER within the Pod
* value for the password key is stored in the file /etc/data/DATABASE_PASSWORD

Run the following commands to deploy a pod that will mount the database-credentials Secret as a volume.

```bash
$ kubectl apply -f /workspace/modules/security/sealed-secrets/pod-volume.yaml
$ kubectl get pod -n secure-secrets
```

View the output logs from the deployed pod to verfiy that the files `/etc/data/DATABASE_USER` and `/etc/data/DATABASE_PASSWORD` within the Pod have been loaded with the expected literal values

```bash test=false
$ kubectl logs pod-volume -n secure-secrets

cat /etc/data/DATABASE_USER
admin
cat /etc/data/DATABASE_PASSWORD
Tru5tN0!
```