---
title: "Sealing your Secrets"
sidebar_position: 70
---

Let's create a new secret `catalog-writer-sealed-db`. We will create a new file `new-catalog-writer-db.yaml` with the same keys and values as the `catalog-writer-db` Secret.

```yaml
apiVersion: v1
data:
  endpoint: Y2F0YWxvZy1teXNxbDozMzA2
  name: Y2F0YWxvZw==
  password: ZGVmYXVsdF9wYXNzd29yZA==
  username: Y2F0YWxvZ191c2Vy
kind: Secret
metadata:
  name: catalog-writer-sealed-db
  namespace: catalog
type: Opaque
```
Now, let’s create SealedSecret YAML manifests with kubeseal.

:::note
Please make sure that there is an inbound rule added to the worker nodes security group allowing port 8080 from the security group associated with your EKS cluster. This rule ensures that the API server can communicate with the sealed-secret on port 8080.
:::

```bash test=false
$ kubeseal --format=yaml < new-catalog-writer-db.yaml > sealed-catalog-writer-db.yaml
```

Alternatively, the public key can be fetched from the controller and use it offline to seal your Secrets

```bash test=false
$ kubeseal --fetch-cert > public-key-cert.pem
$ kubeseal --cert=public-key-cert.pem --format=yaml < new-catalog-writer-db.yaml > sealed-catalog-writer-db.yaml
```

It will create a sealed-secret with the following content:

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  creationTimestamp: null
  name: catalog-writer-sealed-db
  namespace: catalog
spec:
  encryptedData:
    endpoint: AgCS(...)9O0=
    name: AgCk(...)+Ojm
    password: AgBe(...)R91c
    username: AgBu(...)Ykc=
  template:
    data: null
    metadata:
      creationTimestamp: null
      name: catalog-writer-sealed-db
      namespace: catalog
    type: Opaque
```

Let's deploy the SealedSecret to your EKS cluster:

```bash test=false
$ kubectl apply -f sealed-catalog-writer-db.yaml

```

The controller logs shows that it picks up the SealedSecret custom resource that was just deployed, unseals it to create a regular Secret.

```bash test=false
$ kubectl logs sealed-secrets-controller-77747c4b8c-snsxp -n kube-system

2022/11/07 04:28:27 Updating catalog/catalog-writer-sealed-db
2022/11/07 04:28:27 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"catalog", Name:"catalog-writer-sealed-db", UID:"a2ae3aef-f475-40e9-918c-697cd8cfc67d", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"23351", FieldPath:""}): type: 'Normal' reason: 'Unsealed' SealedSecret unsealed successfully
```

Verify that the `catalog-writer-sealed-db` Secret unsealed from the SealedSecret was deployed by the controller to the secure-secrets namespace.

```bash test=false
$ kubectl get secret -n catalog catalog-writer-sealed-db 

NAME                       TYPE     DATA   AGE
catalog-writer-sealed-db   Opaque   4      7m51s
```

Let's redeploy the **catalog** deployment that reads from the above Secret. We have updated the `catalog` deployment to read the `catalog-writer-sealed-db` Secret as folows:

```kustomization
security/sealed-secrets/deployment.yaml
Deployment/catalog
```

```bash
$ kubectl apply -k /workspace/modules/security/sealed-secrets
```

The **catalog-writer-sealed-db** which is a SealedSecret resource is safe to be stored in a Git repository along with YAML manifests pertaining to other Kubernetes resources such as DaemonSets, Deployments, ConfigMaps etc. deployed in the cluster. You can then use a GitOps workflow to manage the deployment of these resources to your cluster.
