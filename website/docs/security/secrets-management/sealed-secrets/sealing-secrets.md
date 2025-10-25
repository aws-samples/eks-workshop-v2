---
title: "Sealing your Secrets"
sidebar_position: 433
---

### Exploring the catalog Pod

Currently, the `catalog` Deployment accesses database credentials from the `catalog-db` secret via environment variables:

- `RETAIL_CATALOG_PERSISTENCE_USER`
- `RETAIL_CATALOG_PERSISTENCE_PASSWORD`

This is done by referencing a Secret with `envFrom`:

```bash
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .envFrom'

- configMapRef:
    name: catalog
- secretRef:
    name: catalog-db
```

Upon exploring the `catalog-db` Secret we can see that it is only encoded with base64 which can be easily decoded as follows hence making it difficult for the secrets manifests to be part of the GitOps workflow.

```file
manifests/base-application/catalog/secrets.yaml
```

```bash
$ kubectl -n catalog get secrets catalog-db --template {{.data.RETAIL_CATALOG_PERSISTENCE_USER}} | base64 -d
catalog%
$ kubectl -n catalog get secrets catalog-db --template {{.data.RETAIL_CATALOG_PERSISTENCE_PASSWORD}} | base64 -d
dYmNfWV4uEvTzoFu%
```

Let's create a new secret `catalog-sealed-db`. We'll create a new file `new-catalog-db.yaml` with the same keys and values as the `catalog-db` Secret.

```file
manifests/modules/security/sealed-secrets/new-catalog-db.yaml
```

Now, let’s create SealedSecret YAML manifests with kubeseal.

```bash
$ kubeseal --format=yaml < ~/environment/eks-workshop/modules/security/sealed-secrets/new-catalog-db.yaml \
  > /tmp/sealed-catalog-db.yaml
```

Alternatively, the public key can be fetched from the controller and use it offline to seal your Secrets:

```bash test=false
$ kubeseal --fetch-cert > /tmp/public-key-cert.pem
$ kubeseal --cert=/tmp/public-key-cert.pem --format=yaml < ~/environment/eks-workshop/modules/security/sealed-secrets/new-catalog-db.yaml \
  > /tmp/sealed-catalog-db.yaml
```

It will create a sealed-secret with the following content:

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  creationTimestamp: null
  name: catalog-sealed-db
  namespace: catalog
spec:
  encryptedData:
    password: AgBe(...)R91c
    username: AgBu(...)Ykc=
  template:
    data: null
    metadata:
      creationTimestamp: null
      name: catalog-sealed-db
      namespace: catalog
    type: Opaque
```

Let's deploy the SealedSecret to your EKS cluster:

```bash
$ kubectl apply -f /tmp/sealed-catalog-db.yaml
```

The controller logs shows that it picks up the SealedSecret custom resource that was just deployed, unseals it to create a regular Secret.

```bash
$ kubectl logs deployments/sealed-secrets-controller -n kube-system

2022/11/07 04:28:27 Updating catalog/catalog-sealed-db
2022/11/07 04:28:27 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"catalog", Name:"catalog-sealed-db", UID:"a2ae3aef-f475-40e9-918c-697cd8cfc67d", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"23351", FieldPath:""}): type: 'Normal' reason: 'Unsealed' SealedSecret unsealed successfully
```

Verify that the `catalog-sealed-db` Secret unsealed from the SealedSecret was deployed by the controller to the secure-secrets namespace.

```bash
$ kubectl get secret -n catalog catalog-sealed-db

NAME                       TYPE     DATA   AGE
catalog-sealed-db          Opaque   4      7m51s
```

Let's redeploy the **catalog** deployment that reads from the above Secret. We have updated the `catalog` deployment to read the `catalog-sealed-db` Secret as follows:

```kustomization
modules/security/sealed-secrets/deployment.yaml
Deployment/catalog
```

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/security/sealed-secrets
$ kubectl rollout status -n catalog deployment/catalog --timeout 30s
```

The **catalog-sealed-db** which is a SealedSecret resource is safe to be stored in a Git repository along with YAML manifests pertaining to other Kubernetes resources such as DaemonSets, Deployments, ConfigMaps etc. deployed in the cluster. You can then use a GitOps workflow to manage the deployment of these resources to your cluster.
