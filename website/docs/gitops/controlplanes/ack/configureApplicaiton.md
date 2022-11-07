---
title: "Bind Application to AWS Resources"
sidebar_position: 4
---

## Deploy the application for production

The application will use the same manifest files as in development, then we will override secrets and configmaps values that will contain the binding information that connects to AWS Services.

```bash
$ kubectl apply -k /workspace/modules/ack/manifests/
```


## Connect to Database Instance
The `DBInstance` status contains the information for connecting to the RDS database instance. The host information can be found in `status.endpoint.address` and the port information can be found in `status.endpoint.port`. The master user name can be found in `spec.masterUsername`.

The database password is in the Secret that is referenced in the DBInstance spec (`spec.masterPassword.name`).

You can extract this information and make it available to your Pods using a [FieldExport](https://aws-controllers-k8s.github.io/community/docs/user-docs/field-export) resource.


FieldExport manifest
```file
ack/rds/fieldexports/rds-fieldexports-writer.yaml
```

Create FieldExport, this will insert the RDS connection values into the configmap **catalog** in the namespace **catalog-prod**
```bash
$ export CATALOG_PASSWORD=$(kubectl get secrets -n default rds-eks-workshop -o go-template='{{.data.password|base64decode}}')
$ kubectl apply -k /workspace/modules/ack/rds/fieldexports
```

Verify that the configmap **catalog** has the correct information
```bash
$ if [[ "$(aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier == 'rds-eks-workshop'].Endpoint.Address" --output text)" ==  "$(kubectl get secret catalog-writer-db -o go-template='{{.data.endpoint|base64decode}}' -n catalog-prod)" ]]; then echo "Catalog configured correctly"; else echo "Error Catalo misconfigured"; false; fi
```

Restart catalog to pick up the new configuration
```bash
$ kubectl rollout restart deployment -n catalog-prod catalog
```

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
```


Verify that the secret **orders** has the correct information
```bash
$ if [[ $(aws mq describe-broker --broker-id "$(aws mq list-brokers --query "BrokerSummaries[?BrokerName == 'mq-eks-workshop'].BrokerId" --output text)" --query 'BrokerInstances[0].Endpoints[0]') == \"$(kubectl get cm orders -o go-template='{{.data.SPRING_ACTIVEMQ_BROKERURL}}'\" -n orders-prod) ]]; then echo "Order configured correctly"; else echo "Error Order misconfigured"; false; fi
```

Restart orders to pickup the new configuration
```bash
$ kubectl rollout restart deployment -n orders-prod orders
```

## Access the Application

Verify that all pods are running in production

```bash
$ kubectl get pods -A | grep '\-prod'
```

Get the hostname of the network load balancer for the UI and open it in the browser

```bash
$ kubectl get svc -n ui-prod ui-nlb
```