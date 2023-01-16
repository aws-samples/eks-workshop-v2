---
title: "Bind Application to AWS Resources"
sidebar_position: 4
---


## Connect to Database Instance
The `DBInstance` status contains the information for connecting to the RDS database instance. The host information can be found in `status.endpoint.address` and the port information can be found in `status.endpoint.port`. The master user name can be found in `spec.masterUsername`.

The database password is in the Secret that is referenced in the DBInstance spec (`spec.masterPassword.name`).

You can extract this information and make it available to your Pods using a [FieldExport](https://aws-controllers-k8s.github.io/community/docs/user-docs/field-export) resource.


FieldExport manifest
```file
ack/rds/fieldexports/rds-fieldexports.yaml
```

Create FieldExport, this will insert the RDS connection values into the secret **catalog-db** in the namespace **catalog-prod**
```bash
$ export CATALOG_PASSWORD=$(kubectl get secrets -n default rds-eks-workshop -o go-template='{{.data.password|base64decode}}')
$ kubectl create ns catalog-prod || true
$ kubectl apply -k /workspace/modules/ack/rds/fieldexports
secret/catalog-db configured
fieldexport.services.k8s.aws/catalog-db-endpoint created
fieldexport.services.k8s.aws/catalog-db-user created
```

It takes some time to provision the AWS managed services, for RDS approximately 10 minutes. The ACK controller will report the status of the reconciliation in the status field of the Kubernetes custom resources.  
You can open the AWS console and see the services being created.

To verify that the provision is done, you can check that the condition “ACK.ResourceSynced” is true using the Kubernetes CLI.

Run the following commands and they will exit once the condition is met.
```bash timeout=1080
$ kubectl wait dbinstances.rds.services.k8s.aws rds-eks-workshop --for=condition=ACK.ResourceSynced --timeout=15m
dbinstances.rds.services.k8s.aws/rds-eks-workshop condition met
```

Verify that the configmap **catalog** has the correct information
```bash
$ if [[ "$(aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier == 'rds-eks-workshop'].Endpoint.Address" --output text)" ==  "$(kubectl get secret catalog-db -o go-template='{{.data.endpoint|base64decode}}' -n catalog-prod)" ]]; then echo "Secret catalog configured correctly"; else echo "Error: Secret catalog misconfigured"; false; fi
Secret catalog configured correctly
```

## Deploy the Application

The application will use the same manifest files as in development, then we will override secrets and configmaps values that will contain the binding information that connects to AWS Services.

```bash
$ kubectl apply -k /workspace/modules/ack/manifests/
...
namespace/catalog-prod created
...
service/catalog created
...
deployment.apps/catalog created
...
```

## Access the Application

Verify that all pods are running in production

```bash
$ kubectl get pods -A | grep '\-prod'
assets-prod                    assets-7bd57dbfcc-cdp9j                         1/1     Running   0              1m
carts-prod                     carts-789498bdbd-wmb2q                          1/1     Running   0              1m
catalog-prod                   catalog-5c4b747759-7fphz                        1/1     Running   0              1m
checkout-prod                  checkout-66b6dcbc45-k9qjr                       1/1     Running   0              1m
orders-prod                    orders-59b94995cf-97pwz                         1/1     Running   0              1m
ui-prod                        ui-795bd46545-49jrh                             1/1     Running   0              1m
```

Get the hostname of the network load balancer for the UI and open it in the browser

```bash
$ kubectl get svc -n ui-prod ui-nlb
NAME     TYPE           CLUSTER-IP      EXTERNAL-IP                                           PORT(S)        AGE
ui-nlb   LoadBalancer   x.x.x.x         k8s-uiprod-uinlb-<uuid>.elb.<region>.amazonaws.com    80:32028/TCP   111m
```
