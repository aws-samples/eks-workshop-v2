---
title: "Bind Application to AWS Resources"
sidebar_position: 10
---

In general when new resources are created, application configuration also needs to be updated to use these new resources. A lot of application developers use environment variables to store configuration, and in Kubernetes it is fairly easy to pass environment variables to containers through the ```env``` spec when creating deployments.

Now, there are two ways to achieve this. First, Configmaps. Configmaps are a core resource in Kubernetes that allow us to pass configuration elements such as Environment variables, text fields and other items in a key-value format to be used in pod specs. Then, we have secrets (which are not encrypted by design - this is important to remember) to push things like passwords/secrets. 

The ACK `FieldExport` custom resource was designed to bridge the gap between managing the control plane of your ACK resources and using the *properties* of those resources in your application. This configures an ACK controller to export any `spec` or `status` field from an ACK resource into a Kubernetes ConfigMap or Secret. These fields are automatically updated when any field value changes. You are then able to mount the ConfigMap or Secret onto your Kubernetes Pods as environment variables that can ingest those values.

The `DBInstance` resource contains the information for connecting to the RDS database instance. The host information can be found in `status.endpoint.address` and the master username  in `spec.masterUsername`. Lets create some `FieldExport` objects to extract these values in to a Kubernetes secret named `catalog-db-ack`.

```file
manifests/modules/automation/controlplanes/ack/rds/fieldexports/rds-fieldexports.yaml
```

Apply this configuration:

```bash
$ export CATALOG_PASSWORD=$(kubectl get secrets -n default catalog-rds-pw -n catalog -o go-template='{{.data.password|base64decode}}')
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/ack/rds/fieldexports
secret/catalog-db configured
fieldexport.services.k8s.aws/catalog-db-endpoint created
fieldexport.services.k8s.aws/catalog-db-user created
```

And now we can see that the `catalog-db-ack` secret has been populated:

```bash
$ kubectl -n catalog get secret -o yaml catalog-db-ack | yq '.data'
endpoint: ZWtzLXdvcmtzaG9wLWNhdGFsb2ctYWNrLmNqa2F0cWQxY25yei51cy13ZXN0LTIucmRzLmFtYXpvbmF3cy5jb20=
password: TVdZM09UUTNNVGc1TUdVM1lXTTNabVV3TjJWbU5qQmo=
username: YWRtaW4=
```

Finally, we can update the application to use the RDS endpoint and credentials sourced from the `catalog-db-ack` secret:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/automation/controlplanes/ack/dynamo
namespace/catalog unchanged
serviceaccount/catalog unchanged
configmap/catalog unchanged
secret/catalog-db unchanged
service/catalog unchanged
service/catalog-mysql unchanged
service/ui-nlb created
deployment.apps/catalog configured
statefulset.apps/catalog-mysql unchanged
$ kubectl rollout status -n catalog deployment/catalog --timeout=120s
```

An NLB has been created to expose the sample application for testing:

```bash
$ kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com
```

To wait until the load balancer has finished provisioning you can run this command:

```bash timeout=610
$ wait-for-lb $(kubectl get service -n ui ui-nlb -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}")
```

Once the load balancer is provisioned you can access it by pasting the URL in your web browser. You will see the UI from the web store displayed and will be able to navigate around the site as a user.

<browser url="http://k8s-ui-uinlb-a9797f0f61.elb.us-west-2.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.png').default}/>
</browser>
