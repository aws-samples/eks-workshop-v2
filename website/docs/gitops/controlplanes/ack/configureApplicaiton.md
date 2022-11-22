---
title: "Bind Application to AWS Resources"
sidebar_position: 4
---

## Deploy the application for production

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


## Connect to Database Instance
The `DBInstance` status contains the information for connecting to the RDS database instance. The host information can be found in `status.endpoint.address` and the port information can be found in `status.endpoint.port`. The master user name can be found in `spec.masterUsername`.

The database password is in the Secret that is referenced in the DBInstance spec (`spec.masterPassword.name`).

You can extract this information and make it available to your Pods using a [FieldExport](https://aws-controllers-k8s.github.io/community/docs/user-docs/field-export) resource.


FieldExport manifest
```file
ack/rds/fieldexports/rds-fieldexports-writer.yaml
```

Create FieldExport, this will insert the RDS connection values into the configmap **catalog-reader-db** in the namespace **catalog-prod**
```bash
$ export CATALOG_PASSWORD=$(kubectl get secrets -n default rds-eks-workshop -o go-template='{{.data.password|base64decode}}')
$ kubectl apply -k /workspace/modules/ack/rds/fieldexports
secret/catalog-reader-db configured
secret/catalog-writer-db configured
fieldexport.services.k8s.aws/catalog-reader-db-endpoint created
fieldexport.services.k8s.aws/catalog-reader-db-user created
fieldexport.services.k8s.aws/catalog-writer-db-endpoint created
fieldexport.services.k8s.aws/catalog-writer-db-user created
```

It takes some time to provision the AWS managed services, for RDS approximately 10 minutes. The ACK controller will report the status of the reconciliation in the status field of the Kubernetes custom resources.  
You can open the AWS console and see the services being created.

To verify that the provision is done, you can check that the condition “ACK.ResourceSynced” is true using the Kubernetes CLI.

Run the following commands and they will exit once the condition is met.
```bash timeout=1080
$ kubectl wait DBInstance rds-eks-workshop --for=condition=ACK.ResourceSynced --timeout=15m
dbinstances.rds.services.k8s.aws/rds-eks-workshop condition met
```

Verify that the configmap **catalog** has the correct information
```bash
$ if [[ "$(aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier == 'rds-eks-workshop'].Endpoint.Address" --output text)" ==  "$(kubectl get secret catalog-reader-db -o go-template='{{.data.endpoint|base64decode}}' -n catalog-prod)" ]]; then echo "Secret catalog configured correctly"; else echo "Error Catalo misconfigured"; false; fi
Secret catalog configured correctly
```

Restart catalog to pick up the new configuration
```bash
$ kubectl rollout restart deployment -n catalog-prod catalog
deployment.apps/catalog restarted
```

<!-- TODO: Uncomment once MQ issue in ACK is resolved https://github.com/aws-controllers-k8s/community/issues/1517
## Connect to Amazon MQ Instance
The `Broker` status contains the information for connecting to the MQ instance. The endpoint information can be found in `status.brokerInstances[0].endpoints[0]` and the password can be found in `.spec.users[0].username`.

You can extract this information and make it available to your Pods using a [FieldExport](https://aws-controllers-k8s.github.io/community/docs/user-docs/field-export) resource.

FieldExport manifest
```file
ack/mq/fieldexports/mq-fieldexports-orders.yaml
```

Create FieldExport, this will insert the RDS connection values into the secret **orders** in the namespace **orders-prod**
```bash
$ export ORDERS_PASSWORD=$(kubectl get secrets -n default mq-eks-workshop -o go-template='{{.data.password|base64decode}}')
$ kubectl apply -k /workspace/modules/ack/mq/fieldexports
configmap/orders configured
fieldexport.services.k8s.aws/orders-host created
fieldexport.services.k8s.aws/orders-user created
```

It takes some time to provision the AWS managed services, for MQ approximately 12 minutes. The ACK controller will report the status of the reconciliation in the status field of the Kubernetes custom resources.  
You can open the AWS console and see the services being created.

To verify that the provision is done, you can check that the condition “ACK.ResourceSynced” is true using the Kubernetes CLI.

Run the following commands and they will exit once the condition is met.
```bash timeout=1080
$ kubectl wait brokers.mq.services.k8s.aws mq-eks-workshop --for=condition=ACK.ResourceSynced --timeout=18m
brokers.mq.services.k8s.aws/mq-eks-workshop condition met
```

Verify that the secret **orders** has the correct information
```bash
$ if [[ $(aws mq describe-broker --broker-id "$(aws mq list-brokers --query "BrokerSummaries[?BrokerName == 'mq-eks-workshop'].BrokerId" --output text)" --query 'BrokerInstances[0].Endpoints[0]') == \"$(kubectl get cm orders -o go-template='{{.data.SPRING_RABBITMQ_ADDRESSES}}'\" -n orders-prod) ]]; then echo "ConfigMap orders configured correctly"; else echo "Error Order misconfigured"; false; fi
ConfigMap orders configured correctly
```

Restart orders to pickup the new configuration
```bash
$ kubectl rollout restart deployment -n orders-prod orders
deployment.apps/orders restarted
```
-->

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
