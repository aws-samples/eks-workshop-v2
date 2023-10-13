---
title: "Setup & Installation"
sidebar_position: 132
---

### Install Kyverno
---

Kyverno can be installed using Helm Charts as well as YAML manifests. In this Lab, we will be installing Kyverno using Helm, If you don't have helm installed, you can refer [instructions here](https://helm.sh/docs/intro/install/) to install Helm.

```
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno --namespace kyverno kyverno/kyverno --create-namespace
```

You can check the resources created in the Kyverno Namespace as below:

```
kubectl get all -n kyverno
```

Sample output as below:

```
NAME                                                           READY   STATUS      RESTARTS   AGE
pod/kyverno-admission-controller-79dcbc777c-rm8qt    1/1     Running   0          23s
pod/kyverno-background-controller-67f4b647d7-5d6l7   1/1     Running   0          23s
pod/kyverno-cleanup-controller-566f7bc8c-6sqp2       1/1     Running   0          23s
pod/kyverno-reports-controller-6f96648477-gndl8      1/1     Running   0          23s

NAME                                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/kyverno-background-controller-metrics   ClusterIP   10.xx.yy.193   <none>        8000/TCP   24s
service/kyverno-cleanup-controller              ClusterIP   10.xx.yy.129    <none>        443/TCP    24s
service/kyverno-cleanup-controller-metrics      ClusterIP   10.xx.yy.204   <none>        8000/TCP   24s
service/kyverno-reports-controller-metrics      ClusterIP   10.xx.yy.24    <none>        8000/TCP   24s
...
```

---
### Install Co-Sign
---

[Co-Sign](https://docs.sigstore.dev/signing/signing_with_containers/) by SigStore can be used to Sign Container Images. Container image signing helps ensure the use of approved images inside your organization, which can help you meet your security and compliance requirements.

Install Co-Sign on your Cloud9 Desktop using below. For any other OS Architectures refer [here](https://docs.sigstore.dev/system_config/installation/)

```
LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-${LATEST_VERSION}.x86_64.rpm"
sudo rpm -ivh cosign-${LATEST_VERSION}.x86_64.rpm
```

To check for Successfull Installation:

```
cosign 
```
Sample output as below:
```
A tool for Container Signing, Verification and Storage in an OCI registry.

Usage:
cosign [command]

Available Commands:
attach                  Provides utilities for attaching artifacts to other artifacts in a registry
attest                  Attest the supplied container image.
[...]
```
