---
title: "Kubernetes events"
sidebar_position: 20
---
**Kubernetes Events** provide a rich source of information that can be used to monitor application and cluster state, respond to failures and perform diagnostics. Events generally denote some state change. Examples include pod creation, adding replicas, scheduling resources. Each event includes a ```type``` field which is set to Normal or Warning to indicate success of failure. A complete list of data fields for Kubernetes events can be found on [kubernetes.io](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/#list-list-or-watch-objects-of-kind-event) or by running ```kubectl explain events```. Events have a limited retention period within the cluster. OpenSearch provides a durable store that simplifies collection, analysis and visualization of the events.   

The following diagram provides an overview of the setup for this module. ```kubernetes-events-exporter``` will be deployed within the EKS cluster to forward events to the OpenSearch domain. An OpenSearch Dashboard that we loaded earlier is used to visualize the events as they occur.

# TODO - Add architecture diagram

We will explore Kubernetes events using the following steps:
1. Deploy Kubernetes events exporter to forward events to OpenSearch 
1. Generate Kubernetes events by spinning up test workloads
1. Explore the events from within the cluster using kubectl 
1. Explore the events using the OpenSearch dashboard 

**Step 1:** Deploy Kubernetes events exporter and configure it to send events to our OpenSearch domain. The base configuration is available [here](https://github.com/VAR::MANIFESTS_OWNER/VAR::MANIFESTS_REPOSITORY/tree/VAR::MANIFESTS_REF/manifests/modules/observability/opensearch/events-exporter). The OpenSearch credentials we retrieved earlier are used to configure the exporter. The second command verifies that the Kubernetes events pod is running.     

```bash timeout=120 wait=30 
$ helm install events-to-opensearch \
    oci://registry-1.docker.io/bitnamicharts/kubernetes-event-exporter \
    --namespace opensearch-exporter --create-namespace \
    -f ~/environment/eks-workshop/modules/observability/opensearch/kube-events/values.yaml \
    --set="config.receivers[0].opensearch.username"="$OPENSEARCH_USER" \
    --set="config.receivers[0].opensearch.password"="$OPENSEARCH_PASSWORD" \
    --set="config.receivers[0].opensearch.hosts[0]"="https://$OPENSEARCH_HOST" \
    --wait
 
$ kubectl get pods -n opensearch-exporter
NAME                                                              READY   STATUS    RESTARTS      AGE
events-to-opensearch-kubernetes-event-exporter-67fc698978-2f9wc   1/1     Running   0             10s
```
**Step 2**: Generate Kubernetes events by spinning up test workloads






**Step 3:** 


After this step you should see the kubernetes events appear in the Opensearch domain




See the Kubernetes events in all namespaces 

```bash 
$ kubectl get events --sort-by='.metadata.creationTimestamp' -A
```


See the most recent event as json in all namespaces 
```bash 
$ kubectl get events --sort-by='.metadata.creationTimestamp' -o json -A | jq '.items[-1]'

```

See events with a warning or failed status
```bash
$ kubectl get events --sort-by='.metadata.creationTimestamp' --field-selector type!=Normal -A 
```


// CreationTimestamp is a timestamp representing the server time when this object was
// created. It is not guaranteed to be set in happens-before order across separate operations.
// Clients may not set this value. It is represented in RFC3339 form and is in UTC.

//LastTimestamp: The time at which the most recent occurrence of this event was recorded.


# See https://wangwei1237.github.io/Kubernetes-in-Action-Second-Edition/docs/Observing_cluster_events_via_Event_objects.html
Name	The name of this Event object instance. Useful only if you want to retrieve the given object from the API.
Type	The type of the event. Either Normal or Warning.
Reason	The machine-facing description why the event occurred.
Source	The component that reported this event. This is usually a controller.
Object	The object instance to which the event refers. For example, node/xyz.
Sub-object	The sub-object to which the event refers. For example, what container of the pod.
Message	The human-facing description of the event.
First seen	The first time this event occurred. Remember that each Event object is deleted after a while, so this may not be the first time that the event actually occurred.
Last seen	Events often occur repeatedly. This field indicates when this event last occurred.
Count	The number of times this event has occurred.


https://www.datadoghq.com/blog/monitor-kubernetes-events/#failed-events


Sample output of event in JSON format  
```
{
  "apiVersion": "v1",
  "count": 1,
  "eventTime": null,
  "firstTimestamp": null,
  "involvedObject": {
    "apiVersion": "v1",
    "kind": "RabbitMQ",
    "name": "pod/rabbitmq-0",
    "namespace": "rabbitmq"
  },
  "kind": "Event",
  "lastTimestamp": "2023-10-13T00:04:03Z",
  "message": "Node rabbit@rabbitmq-0.rabbitmq-headless.rabbitmq.svc.cluster.local is registered",
  "metadata": {
    "creationTimestamp": "2023-10-13T00:04:03Z",
    "name": "rabbitmq-0.1697155443634",
    "namespace": "rabbitmq",
    "resourceVersion": "38684",
    "uid": "14b78a28-b16b-41f2-8acf-657082d4e10c"
  },
  "reason": "Created",
  "reportingComponent": "",
  "reportingInstance": "",
  "source": {
    "component": "rabbitmq-0/rabbitmq_peer_discovery",
    "host": "rabbitmq-0"
  },
  "type": "Normal"
}
```

# Launch OpenSearch dashboard 



# Load ndjson for dashboards using either Terraform or curl (from this file)




# Simulate failures 
 Failed events
 - Pod with bad image name - failure to schedule -- then patch ImagePullBackOff
 - Pod is referencing missing secret
 - Pod that requires a GPU 
 - Deployment cannot scale 
 - Fail to schedule pod because of 




# 


View events in OpenSearch dashboard 



# 

