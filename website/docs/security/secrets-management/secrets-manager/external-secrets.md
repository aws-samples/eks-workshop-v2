---
title: "External Secrets Operator"
sidebar_position: 64
---

The `prepare-environment` script that you ran in a [previous step](./index.md), has already deployed the External Secrets Operator addon required for this lab.

Let's validate the created addon.

```bash
$ kubectl -n external-secrets get pods
NAME                                                READY   STATUS    RESTARTS   AGE
external-secrets-6d95d66dc8-5trlv                   1/1     Running   0          7m
external-secrets-cert-controller-774dff987b-krnp7   1/1     Running   0          7m
external-secrets-webhook-6565844f8f-jxst8           1/1     Running   0          7m
$ kubectl -n external-secrets get sa 
NAME                  SECRETS   AGE
default               0         7m
external-secrets-sa   0         7m
```

As you can see, you have a ServiceAccount named `external-secrets-sa`, this SA is tied to an [IRSA](../../iam-roles-for-service-accounts/), with access to AWS Secrets Manager, for retrieving secrets information.

```bash
$ kubectl -n external-secrets describe sa external-secrets-sa | grep Annotations
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::068535243777:role/eks-workshop-external-secrets-sa-irsa
```

In addition to that, you'll need to create a new cluster resource called `ClusterSecretStore` which is a cluster wide SecretStore that can be referenced by all ExternalSecrets from all namespaces.

```file
manifests/modules/security/secrets-manager/cluster-secret-store.yaml
```

```bash
$ cat eks-workshop/modules/security/secrets-manager/cluster-secret-store.yaml | envsubst | kubectl apply -f -
```

Take a deeper look in this newly created resource specifications.

```bash
$ kubectl get clustersecretstores.external-secrets.io 
NAME                   AGE   STATUS   CAPABILITIES   READY
cluster-secret-store   81s   Valid    ReadWrite      True
$ kubectl get clustersecretstores.external-secrets.io cluster-secret-store  -o yaml | yq '.spec'
provider:
  aws:
    auth:
      jwt:
        serviceAccountRef:
          name: external-secrets-sa
          namespace: external-secrets
    region: us-west-2
    service: SecretsManager

```

You can see here, that it's using a [JSON Web Token (jwt)](https://jwt.io/), referenced to the ServiceAccount we just checked, to sync with AWS Secrets Manager.

Let's move forward and create an `ExternalSecret`, that describes what data should be fetched from AWS Secrets Manager, how the data should be transformed and saved as a Kubernetes Secret. And also patch our `catalog` Deployment to use the External Secret as source for the credentials.

```kustomization
modules/security/secrets-manager/external-secrets/kustomization.yaml
Deployment/catalog
ExternalSecret/catalog-external-secret
```

```bash
$ kubectl apply -k eks-workshop/modules/security/secrets-manager/external-secrets/
```

Check the newly created `ExternalSecret` resouce.

```bash
$ kubectl -n catalog get externalsecrets.external-secrets.io                                                                                                                                                                                                                            
NAME                      STORE                  REFRESH INTERVAL   STATUS         READY
catalog-external-secret   cluster-secret-store   1h                 SecretSynced   True
```

Verify that the resource has a `SecretSynced` status, which means that it was successfully syncronized from AWS Secrets Manager. Let's take a closer look to this resource specifications.

```bash
$ kubectl -n catalog get externalsecrets.external-secrets.io catalog-external-secret -o yaml | yq '.spec'
dataFrom:
  - extract:
      conversionStrategy: Default
      decodingStrategy: None
      key: eks-workshop/catalog-secret
refreshInterval: 1h
secretStoreRef:
  kind: ClusterSecretStore
  name: cluster-secret-store
target:
  creationPolicy: Owner
  deletionPolicy: Retain
```

Notice the `key` and the `secretStoreRef` parameter, pointing to the secret we stored on AWS Secrets Manager, and the `ClusterSecretStore` previously created. Also the `refreshInterval` is set to 1 hours, which means that the value from this secret will be checked and refreshed every hour.

But how do we use this ExternalSecret in our Pods? After we create this resouces, it automatically created a Kubernetes secret with the same name in the Namespace.

```bash
$ kubectl -n catalog get secrets
NAME                      TYPE     DATA   AGE
catalog-db                Opaque   2      21h
catalog-external-secret   Opaque   2      1m
catalog-secret            Opaque   2      5h40m
```

Take a deeper look in this secret.

```bash
$ kubectl -n catalog get secret catalog-external-secret -o yaml | yq '.metadata.ownerReferences'
- apiVersion: external-secrets.io/v1beta1
  blockOwnerDeletion: true
  controller: true
  kind: ExternalSecret
  name: catalog-external-secret
  uid: b8710001-366c-44c2-8e8d-462d85b1b8d7
```

See that it has an `ownerReference` that points to External Secrets Operator.

Now check that the `catalog` Pod, is already updated with the values from this new secret, and it's up and running!

```bash
$ kubectl -n catalog get pods
NAME                       READY   STATUS    RESTARTS   AGE
catalog-777c4d5dc8-lmf6v   1/1     Running   0          1m
catalog-mysql-0            1/1     Running   0          24h
$ kubectl -n catalog get deployment catalog -o yaml | yq '.spec.template.spec.containers[] | .env'
- name: DB_USER
  valueFrom:
    secretKeyRef:
      key: username
      name: catalog-external-secret
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      key: password
      name: catalog-external-secret
```

### Conclusion

In conclusion, there is no best option on choosing between **AWS Secrets and Configuration Provider (ASCP)** vs. **External Secrets Operator (ESO)** in order to manage your secrets stored on **AWS Secrets Manager**. 

Both tools have their specific advantages, for example, ASCP can help you avoid exposing secrets as environment variables, mounting them as volumes directly from AWS Secrets Manager into a Pod, the drawback is the need to manage those volumes. In the other hand ESO makes easier the Kubernetes Secrets lifecycle management, having also a cluster wide SecretStore, however it doesn't allow you to use Secrets as volumes. It all depends on your use case, and having both can bring you a lot more flexibility and security with Secrets Management.
