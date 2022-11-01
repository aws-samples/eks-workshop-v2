---
title: Circuit Breaking
sidebar_position: 50
weight: 5
---

Building resilient microservice applications requires the use of circuit breaking, which is a critical design pattern. Circuit breaking allows you to build applications that reduce the impact of network failures, latency spikes, and other undesirable network effects.

This task will show you how to configure circuit breaking for connections, requests, and outlier detection.

You will configure circuit breaking rules in this task and then test the configuration by intentionally "tripping" the circuit breaker.


### Configuring the circuit breaker
Create a destination rule to apply circuit breaking settings when calling the *productpage* service:
```yaml
kubectl apply -n test -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutiveErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
EOF
```

### Load Testing Using Fortio
Fortio allows you to control the number of connections, concurrency, and delay for outgoing HTTP calls. This client will be used to "trip" the destination rule's circuit breaker policies.

Deploy the Fortio application
```yaml
kubectl apply -n test -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: fortio
  labels:
    app: fortio
spec:
  ports:
  - port: 8080
    name: http
  selector:
    app: fortio
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fortio-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fortio
  template:
    metadata:
      annotations:
        # This annotation causes Envoy to serve cluster.outbound statistics via 15000/stats
        # in addition to the stats normally served by Istio.  The Circuit Breaking example task
        # gives an example of inspecting Envoy stats.
        sidecar.istio.io/statsInclusionPrefixes: cluster.outbound,cluster_manager,listener_manager,http_mixer_filter,tcp_mixer_filter,server,cluster.xds-grpc
      labels:
        app: fortio
    spec:
      containers:
      - name: fortio
        image: fortio/fortio:latest_release
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http-fortio
        - containerPort: 8079
          name: grpc-ping
EOF
```

### Tripping the circuit breaker
In your DestinationRule above, you specified `maxConnections: 1` and `http1MaxPendingRequests: 1`. According to these rules, if you attempt to open more than one connection and request at the same time, you should experience some failures when the istio-proxy opens the circuit for additional requests and connections.

Log in to *Fortio* pod and use the fortio tool to call the *productpage* service. Call the service with two concurrent connections and send 20 requests:
```shell
FORTIO_POD_NAME=$(kubectl get pod -n test | grep fortio | awk '{ print $1 }')
kubectl exec -n test -it $FORTIO_POD_NAME  -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 http://productpage:9080
```
Output:
```shell
...
15:04:22 W http_client.go:922> [1] Non ok http code 503 (HTTP/1.1 503)
15:04:22 W http_client.go:922> [1] Non ok http code 503 (HTTP/1.1 503)
15:04:22 W http_client.go:922> [1] Non ok http code 503 (HTTP/1.1 503)
15:04:22 W http_client.go:922> [1] Non ok http code 503 (HTTP/1.1 503)
...
Code 200 : 16 (80.0 %)
Code 503 : 4 (20.0 %)
...
```
You probably get surprised that most of the requests (80%) were successful. That's because `istio-proxy` allows for some flexibility. 

Let's see, how it will look like when you increase the number of concurrent connections up to 10 and number of requests to 100.
```shell
kubectl exec -n test -it $FORTIO_POD_NAME  -c fortio -- /usr/bin/fortio load -c 10 -qps 0 -n 100 http://productpage:9080
```
Output:
```shell
...
Code 200 : 10 (10.0 %)
Code 503 : 90 (90.0 %)
...
```
This time, you can see the expected circuit breaking behavior. Only 10% of the requests were successful, and the rest were trapped by circuit breaking.

To get more details, you can query the stats of GET requests on the istio-proxy 
```shell
kubectl exec -n test $FORTIO_POD_NAME -c istio-proxy -- pilot-agent request GET stats | grep productpage | grep pending
```
Output:
```shell
cluster.outbound|9080||productpage.test.svc.cluster.local.circuit_breakers.default.remaining_pending: 1
cluster.outbound|9080||productpage.test.svc.cluster.local.circuit_breakers.default.rq_pending_open: 0
cluster.outbound|9080||productpage.test.svc.cluster.local.circuit_breakers.high.rq_pending_open: 0
cluster.outbound|9080||productpage.test.svc.cluster.local.upstream_rq_pending_active: 0
cluster.outbound|9080||productpage.test.svc.cluster.local.upstream_rq_pending_failure_eject: 0
cluster.outbound|9080||productpage.test.svc.cluster.local.upstream_rq_pending_overflow: 1594
cluster.outbound|9080||productpage.test.svc.cluster.local.upstream_rq_pending_total: 469
```
You can see 1594 for the upstream_rq_pending_overflow value which means 1594 calls so far have been flagged for circuit breaking.

Now, because you have completed this task, there is no need to keep the destinationRule you created at the begining of this task. So go ahead and delete it.
```shell
$ kubectl delete -n test destinationrule productpage
```