---
title: "Kubernetes events"
sidebar_position: 10
---

Deploy the Kubernetes events exporter 


```bash wait=60
$ helm install events-to-opensearch \
    oci://registry-1.docker.io/bitnamicharts/kubernetes-event-exporter \
    --namespace opensearch-exporter --create-namespace \
    -f ~/environment/eks-workshop/modules/observability/opensearch/kube-events/values.yaml \
    --set="config.receivers[0].opensearch.username"=$OPENSEARCH_USER \
    --set="config.receivers[0].opensearch.password"=$OPENSEARCH_PASSWORD \
    --set="config.receivers[0].opensearch.hosts[0]"="https://$OPENSEARCH_HOST" \
    --wait
```

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

