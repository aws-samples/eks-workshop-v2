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

Lets create the secrets that the catalog microservice will use when the application is deploy to production. 

Set the namespace to create secrets
```bash
$ CATALOG_NAMESPACE=catalog-prod
```

Get the password from the previous section
```bash
$ CATALOG_PASSWORD=$(kubectl get secrets -n default rds-eks-workshop -o go-template='{{.data.password|base64decode}}')
```

Create a yaml manifest for FieldExport
```bash
$ cat <<EOF > rds-field-exports.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${CATALOG_NAMESPACE}
---
apiVersion: v1
kind: Secret
metadata:
  name: catalog-reader-db
  namespace: ${CATALOG_NAMESPACE}
data: {}
stringData:
  password: ${CATALOG_PASSWORD}
  name: catalog
---
apiVersion: services.k8s.aws/v1alpha1
kind: FieldExport
metadata:
  name: catalog-reader-db-endpoint
spec:
  to:
    name: catalog-reader-db
    kind: secret
    namespace: ${CATALOG_NAMESPACE}
    key: endpoint
  from:
    path: ".status.endpoint.address"
    resource:
      group: rds.services.k8s.aws
      kind: DBInstance
      name: ${CATALOG_INSTANCE_NAME}
---
apiVersion: services.k8s.aws/v1alpha1
kind: FieldExport
metadata:
  name: catalog-reader-db-user
spec:
  to:
    name: catalog-reader-db
    kind: secret
    namespace: ${CATALOG_NAMESPACE}
    key: username
  from:
    path: ".spec.masterUsername"
    resource:
      group: rds.services.k8s.aws
      kind: DBInstance
      name: ${CATALOG_INSTANCE_NAME}
---
apiVersion: v1
kind: Secret
metadata:
  name: catalog-writer-db
  namespace: ${CATALOG_NAMESPACE}
data: {}
stringData:
  password: ${CATALOG_PASSWORD}
  name: catalog
---
apiVersion: services.k8s.aws/v1alpha1
kind: FieldExport
metadata:
  name: catalog-writer-db-endpoint
spec:
  to:
    name: catalog-writer-db
    kind: secret
    namespace: ${CATALOG_NAMESPACE}
    key: endpoint
  from:
    path: ".status.endpoint.address"
    resource:
      group: rds.services.k8s.aws
      kind: DBInstance
      name: ${CATALOG_INSTANCE_NAME}
---
apiVersion: services.k8s.aws/v1alpha1
kind: FieldExport
metadata:
  name: catalog-writer-db-user
spec:
  to:
    name: catalog-writer-db
    kind: secret
    namespace: ${CATALOG_NAMESPACE}
    key: username
  from:
    path: ".spec.masterUsername"
    resource:
      group: rds.services.k8s.aws
      kind: DBInstance
      name: ${CATALOG_INSTANCE_NAME}
EOF
```

Create FieldExport resources
```bash
$ kubectl apply -f rds-field-exports.yaml
```

Verify that the secrets are created

```bash
$ kubectl get secret -n catalog-prod catalog-reader-db -o go-template='{{.data.endpoint|base64decode}}{{"\n"}}'
$ kubectl get secret -n catalog-prod catalog-writer-db -o go-template='{{.data.endpoint|base64decode}}{{"\n"}}'
```

## Connect to Amazon MQ Instance
The `Broker` status contains the information for connecting to the MQ instance. The endpoint information can be found in `status.brokerInstances[0].endpoints[0]` and the password can be found in `.spec.users[0].username`.

You can extract this information and make it available to your Pods using a [FieldExport](https://aws-controllers-k8s.github.io/community/docs/user-docs/field-export) resource.

Lets create the configmap that the orders microservice will use when the application is deploy to production.

Set the namespace to create configmap
```bash
$ ORDERS_NAMESPACE=orders-prod
```

Get the password from the previous section
```bash
$ ORDERS_PASSWORD=$(kubectl get secrets -n default mq-eks-workshop -o go-template='{{.data.password|base64decode}}')
```

Create a yaml manifest for FieldExport
```bash
$ cat <<EOF > mq-field-exports.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${ORDERS_NAMESPACE}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: orders
  namespace: ${ORDERS_NAMESPACE}
data:
  SPRING_PROFILES_ACTIVE: mysql,activemq
  SPRING_ACTIVEMQ_PASSWORD: ${ORDERS_PASSWORD}
---
apiVersion: services.k8s.aws/v1alpha1
kind: FieldExport
metadata:
  name: orders-host
spec:
  to:
    name: orders
    kind: configmap
    namespace: ${ORDERS_NAMESPACE}
    key: SPRING_ACTIVEMQ_BROKERURL
  from:
    path: ".status.brokerInstances[0].endpoints[0]"
    resource:
      group: mq.services.k8s.aws
      kind: Broker
      name: ${ORDERS_INSTANCE_NAME}
---
apiVersion: services.k8s.aws/v1alpha1
kind: FieldExport
metadata:
  name: orders-user
spec:
  to:
    name: orders
    kind: configmap
    namespace: ${ORDERS_NAMESPACE}
    key: SPRING_ACTIVEMQ_USER
  from:
    path: ".spec.users[0].username"
    resource:
      group: mq.services.k8s.aws
      kind: Broker
      name: ${ORDERS_INSTANCE_NAME}
EOF
```

Create FieldExport resources
```bash
$ kubectl apply -f mq-field-exports.yaml 
```

Verify that the configmap is created

```bash
$ kubectl get cm -n orders-prod orders -o go-template='{{.data.SPRING_ACTIVEMQ_BROKERURL}}{{"\n"}}'
$ kubectl get cm -n orders-prod orders -o go-template='{{.data.SPRING_ACTIVEMQ_USER}}{{"\n"}}'
```

## Restart the deployments

For the microservices pods to be able to pick the new AWS binding information in their environments variables, we have to restart the deployment.

Restart orders
```bash
$ kubectl rollout restart deployment -n orders-prod orders
```

Restart catalog
```bash
$ kubectl rollout restart deployment -n catalog-prod catalog
```

Verify that app pods are running in production

```bash
$ kubectl get pods -A | grep '\-prod'
```

Get the hostname of the network load balancer for the UI and open it in the browser

```bash
$ kubectl get svc -n ui-prod ui-nlb
```