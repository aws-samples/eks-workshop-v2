---
title: "Canary Deployment"
sidebar_position: 30
---

Gateway API provides native support for weighted traffic splitting, enabling canary deployments without additional tools or service mesh infrastructure. In this section, we'll deploy a new version of the UI application and progressively shift traffic from the original version to the new one using HTTPRoute weights.

With traditional Kubernetes Ingress, weighted traffic splitting is not natively supported — you would need a service mesh like Istio or App Mesh to achieve this. Gateway API makes it a first-class feature through the `backendRefs` weight field.

## Deploy the new UI version

First, we'll deploy a second version of the UI application (`ui-v2`) that uses an orange theme to make it visually distinguishable from the original blue theme:

::yaml{file="manifests/modules/exposing/gateway-api/canary/deployment-ui-v2.yaml" paths="metadata.name,spec.template.spec.containers.0.env"}

The key difference is the `RETAIL_UI_THEME=orange` environment variable, which produces a visually distinct orange-themed UI.

We also need a Service to route traffic to the new pods:

::yaml{file="manifests/modules/exposing/gateway-api/canary/service-ui-v2.yaml" paths="metadata.name,spec.selector"}

Apply both resources:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/deployment-ui-v2.yaml
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/service-ui-v2.yaml
```

Wait for the new pods to be ready:

```bash timeout=120
$ kubectl wait --for=condition=Ready pods -l app.kubernetes.io/version=v2 -n ui --timeout=120s
```

## Apply the 90/10 canary route

Now we'll replace the existing `ui-route` HTTPRoute with a weighted version that sends 90% of traffic to the original UI and 10% to ui-v2:

::yaml{file="manifests/modules/exposing/gateway-api/canary/httproute-ui-canary.yaml" paths="spec.rules.0.backendRefs"}

Notice how the `backendRefs` field now contains two entries with explicit `weight` values. The Gateway controller distributes traffic proportionally based on these weights.

Apply the canary HTTPRoute:

```bash hook=canary hookTimeout=180
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/httproute-ui-canary.yaml
```

## Test the traffic split

Send multiple requests to the Gateway and observe the distribution. Approximately 10% of responses should come from the orange-themed ui-v2:

```bash timeout=60
$ export GATEWAY_URL=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')
$ for i in $(seq 1 20); do curl -s $GATEWAY_URL | grep "theme" ; done
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-orange.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-orange.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-orange.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-default.css"theme: {
href="/assets/css/theme-orange.css"theme: {
```

You should see that most responses return `theme-default` while roughly 1-2 out of 20 requests return `theme-orange`, confirming the 90/10 traffic split is working.

## Increase traffic to 50/50

Once you're confident the new version is working correctly, increase the canary weight to 50%:

::yaml{file="manifests/modules/exposing/gateway-api/canary/httproute-canary-50-50.yaml" paths="spec.rules.0.backendRefs"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/httproute-canary-50-50.yaml
```

Test again to see the even split:

```bash timeout=60
$ for i in $(seq 1 20); do curl -s $GATEWAY_URL | grep "theme" ; done
```

You should now see roughly half of the responses returning the orange theme.

## Complete the rollout

When you're satisfied with the new version, shift all traffic to ui-v2 by setting the weights to 0/100:

::yaml{file="manifests/modules/exposing/gateway-api/canary/httproute-canary-0-100.yaml" paths="spec.rules.0.backendRefs"}

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/canary/httproute-canary-0-100.yaml
```

Verify that all traffic now goes to the new version:

```bash timeout=60
$ for i in $(seq 1 20); do curl -s $GATEWAY_URL | grep "theme" ; done
```

All responses should now return the orange theme, confirming the full cutover to ui-v2.

<Browser url="http://k8s-ui-retailst-xxxxxxxxxx.us-west-2.elb.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home-orange.webp').default}/>
</Browser>

## Summary

In this section we performed a progressive canary deployment using Gateway API's native weighted traffic splitting:

1. Deployed a new version of the UI with a distinct visual theme
2. Started with a 90/10 split to test with minimal risk
3. Increased to 50/50 after validating the new version
4. Completed the rollout with a 0/100 split

### Gateway API vs Ingress comparison

| Capability | Gateway API | Kubernetes Ingress |
|---|---|---|
| Weighted traffic splitting | Native via `backendRefs` weights | Not supported natively |
| Canary deployments | Built-in, no extra tools needed | Requires service mesh or annotations |
| Cross-namespace routing | Native via `parentRefs` | Requires IngressGroup or similar workarounds |
| Role-oriented model | GatewayClass → Gateway → HTTPRoute | Single Ingress resource |
| Multiple backends per route | Native with weights and filters | Limited to single backend per path |
| Progressive rollouts | Declarative weight updates | Requires external controllers |

Gateway API's native traffic splitting makes canary deployments straightforward and declarative, eliminating the need for additional service mesh infrastructure or custom annotations that traditional Ingress requires.
