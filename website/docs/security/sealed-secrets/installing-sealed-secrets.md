---
title: "Installing Sealed Secrets"
sidebar_position: 60
---

## Installing the kubeseal Client

The kubeseal client has already been installed as part of the setup.

## Installing the Custom Controller and CRD for SealedSecret

Install the SealedSecret CRD, controller and RBAC artifacts on your EKS cluster as follows:

```bash
$ kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
```

Now we will check the status of the pod

```bash
$ kubectl get pods -n kube-system | grep sealed-secrets-controller

sealed-secrets-controller-77747c4b8c-snsxp      1/1     Running   0          5s
```
The logs of the sealed-secrets controller show that the controller tries to find any existing private keys during startup. If there are no private keys found, then it creates a new secret with the certificate details.

```bash test=false
$ kubectl logs sealed-secrets-controller-77747c4b8c-snsxp -n kube-system

controller version: 0.18.0
2022/10/18 09:17:01 Starting sealed-secrets controller version: 0.18.0
2022/10/18 09:17:01 Searching for existing private keys
2022/10/18 09:17:02 New key written to kube-system/sealed-secrets-keyvkl9w
2022/10/18 09:17:02 Certificate is 
-----BEGIN CERTIFICATE-----
MIIEzTCCArWgAwIBAgIRAPsk+UrW9GlPu4gXN1qKqGswDQYJKoZIhvcNAQELBQAw
ADAeFw0yMjEwMTgwOTE3MDJaFw0zMjEwMTUwOTE3MDJaMAAwggIiMA0GCSqGSIb3
(...)
q5P11EvxPBfIt9xDx5Jz4JWp5M7wWawGaeBqTmTDbSkc
-----END CERTIFICATE-----

2022/10/18 09:17:02 HTTP server serving on :8080
```

We can view the contents of the Secret which contains the public/private key pair in YAML format as follows:

```bash
$ kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml

apiVersion: v1
items:
- apiVersion: v1
  data:
    tls.crt: LS0tL(...)LQo=
    tls.key: LS0tL(...)LS0K
  kind: Secret
  metadata:
    creationTimestamp: "2022-10-18T09:17:02Z"
    generateName: sealed-secrets-key
    labels:
      sealedsecrets.bitnami.com/sealed-secrets-key: active
    name: sealed-secrets-keyvkl9w
    namespace: kube-system
    resourceVersion: "129381"
    uid: 23f5e70c-2537-4c38-a85c-b410f1dcf9a6
  type: kubernetes.io/tls
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

## Helm support

We can also install the sealed-secrets controller and corresponding components using helm. While trying to install the controller using [helm](https://github.com/bitnami-labs/sealed-secrets#helm-chart), there are certain changes that have to be made as follows:

* The `fullnameOverride` parameter has to be provided so that the controller starts with the name `sealed-secrets-controller`.

Example command:
```bash test=false
$ helm install sealed-secrets -n kube-system --set-string fullnameOverride=sealed-secrets-controller sealed-secrets/sealed-secrets
```
* If the `fullnameOverride` parameter is not provided during helm install, then the kubeseal command must have the flag `--controller-name sealed-secrets` because kubeseal tries to access the controller with the name sealed-secrets-controller by default.

Example command:
```bash test=false
$ kubeseal --controller-name sealed-secrets <args>
```


**NOTE**: Please see other changes in the sealed-secrets [repository](https://github.com/bitnami-labs/sealed-secrets) that may be introduced for the helm support for future controller versions.