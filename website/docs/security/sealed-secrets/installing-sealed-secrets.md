---
title: "Installing Sealed Secrets"
sidebar_position: 60
---

The `kubeseal` CLI is used to interact with the sealed secrets controller, and has already been installed in Cloud9.

The first thing we'll do is install the sealed secrets controller in the EKS cluster:

```bash
$ kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
$ kubectl wait --for=condition=Ready --timeout=30s pods -l name=sealed-secrets-controller -n kube-system
```

Now we'll check the status of the pod

```bash
$ kubectl get pods -n kube-system -l name=sealed-secrets-controller
sealed-secrets-controller-77747c4b8c-snsxp      1/1     Running   0          5s
```

The logs of the sealed secrets controller show that the controller tries to find any existing private keys during startup. If there are no private keys found, then it creates a new secret with the certificate details.

```bash
$ kubectl logs deployments/sealed-secrets-controller -n kube-system
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

We can view the contents of the Secret which contains the sealing key as a public/private key pair in YAML format as follows:

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
