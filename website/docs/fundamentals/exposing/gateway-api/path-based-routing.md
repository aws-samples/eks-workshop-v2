---
title: "Path-Based Routing"
sidebar_position: 20
---

One of the key advantages of Gateway API is the ability to route traffic from a single Gateway to multiple backend services across different namespaces. In this section, we'll add a second HTTPRoute that directs `/catalog` requests to the Catalog API while the existing UI route continues to serve all other traffic.

## Current state

At this point we have a single HTTPRoute (`ui-route`) in the `ui` namespace that routes all traffic with path prefix `/` to the UI service:

```bash
$ kubectl get httproute -n ui
NAME       HOSTNAMES   AGE
ui-route               5m
```

All requests to the Gateway ALB currently reach the UI application regardless of path.

## Add the Catalog HTTPRoute

We'll create a new HTTPRoute in the `catalog` namespace that routes requests with path prefix `/catalog` to the Catalog service:

::yaml{file="manifests/modules/exposing/gateway-api/path-based-routing/httproute-catalog.yaml" paths="metadata.namespace,spec.parentRefs,spec.rules"}

Key points:

1. The HTTPRoute is created in the `catalog` namespace, alongside the service it routes to
2. The `parentRefs` field references the Gateway `retail-store-gateway` in the `ui` namespace — this is cross-namespace routing
3. The rule matches requests with path prefix `/catalog` and forwards them to the `catalog` service on port 80

Apply the Catalog HTTPRoute:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/path-based-routing/httproute-catalog.yaml
```

## Configure the Catalog health check

The catalog service exposes its health endpoint at `/health` rather than the default root path `/`. We need a `TargetGroupConfiguration` to tell the ALB where to check health:

::yaml{file="manifests/modules/exposing/gateway-api/path-based-routing/targetgroupconfig-catalog.yaml" paths="spec.targetReference,spec.defaultConfiguration.healthCheckConfig"}

1. `targetReference` identifies the catalog Service
2. `healthCheckPath: /health` tells the ALB to check `/health` instead of `/`

Apply the TargetGroupConfiguration:

```bash hook=path-routing hookTimeout=180
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/path-based-routing/targetgroupconfig-catalog.yaml
```

## Verify both routes

Confirm that both HTTPRoutes are now attached to the Gateway:

```bash
$ kubectl get httproute -A
NAMESPACE   NAME            HOSTNAMES   AGE
ui          ui-route                    5m
catalog     catalog-route               30s
```

Test that the `/catalog` path returns Catalog API JSON:

```bash timeout=60
$ export GATEWAY_URL=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')
$ curl -s $GATEWAY_URL/catalog/products | jq .
```

You'll receive a JSON response from the Catalog service containing product data.

Verify that the root path `/` still returns the UI:

```bash
$ curl --head -X GET -s $GATEWAY_URL
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 19973
Connection: keep-alive
Content-Language: en-US
```

The `Content-Type: text/html` response confirms the UI service is responding on `/`, while the Catalog API is now accessible on `/catalog` — both served through the same Gateway ALB.

## Cross-namespace routing

This pattern demonstrates one of Gateway API's key advantages over traditional Ingress. With Ingress, routing rules and the load balancer configuration are tightly coupled in a single resource, and sharing an ALB across namespaces requires workarounds like the IngressGroup annotation.

With Gateway API, the architecture is role-oriented:

- **Cluster operators** manage the Gateway (load balancer infrastructure) in one namespace
- **Application teams** create HTTPRoutes in their own namespaces, referencing the shared Gateway via `parentRefs`

The Catalog team can independently manage their routing rules in the `catalog` namespace without needing access to the `ui` namespace where the Gateway lives. The Gateway controller handles the attachment automatically, provided the Gateway allows it through its listener configuration.

This separation of concerns makes Gateway API a natural fit for multi-team clusters where different teams own different services but share common infrastructure.
