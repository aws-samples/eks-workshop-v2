---
title: "Exposing the UI"
sidebar_position: 10
---

In this section we'll create the Gateway API resources needed to expose the UI application through an Application Load Balancer.

## Create the GatewayClass

A GatewayClass defines which controller is responsible for managing Gateway resources. We'll create one that uses the AWS Load Balancer Controller:

::yaml{file="manifests/modules/exposing/gateway-api/exposing-ui/gatewayclass.yaml" paths="spec.controllerName"}

This tells Kubernetes that any Gateway referencing the `aws-alb` class should be handled by the AWS Load Balancer Controller.

Apply the GatewayClass:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/exposing-ui/gatewayclass.yaml
```

## Configure the Load Balancer

In LBC v3.x with Gateway API, load balancer settings are configured through a `LoadBalancerConfiguration` CRD rather than annotations. This resource defines the ALB scheme:

::yaml{file="manifests/modules/exposing/gateway-api/exposing-ui/loadbalancerconfig.yaml" paths="spec.scheme"}

`scheme: internet-facing` makes the ALB publicly accessible from the internet.

Apply the LoadBalancerConfiguration:

```bash
$ export SOURCE_RANGES=$(echo $INBOUND_CIDRS | jq -R 'split(",")')
$ cat ~/environment/eks-workshop/modules/exposing/gateway-api/exposing-ui/loadbalancerconfig.yaml | envsubst | kubectl apply -f -
```

## Create the Gateway

The Gateway resource provisions the actual load balancer infrastructure. It references the GatewayClass and the LoadBalancerConfiguration:

::yaml{file="manifests/modules/exposing/gateway-api/exposing-ui/gateway.yaml" paths="spec.gatewayClassName,spec.infrastructure,spec.listeners"}

Key points:

1. `gatewayClassName: aws-alb` links this Gateway to the GatewayClass we created
2. `infrastructure.parametersRef` references the LoadBalancerConfiguration for ALB settings
3. The listener accepts HTTP traffic on port 80

Apply the Gateway:

```bash timeout=600
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/exposing-ui/gateway.yaml
$ kubectl wait --for=condition=Programmed gateway/retail-store-gateway -n ui --timeout=600s
```

## Create the HTTPRoute

An HTTPRoute defines how traffic arriving at the Gateway should be routed to backend services. We'll route all traffic with path prefix `/` to the UI service:

::yaml{file="manifests/modules/exposing/gateway-api/exposing-ui/httproute-ui.yaml" paths="spec.parentRefs,spec.rules"}

1. `parentRefs` links this route to our Gateway
2. The rule matches all paths starting with `/` and forwards traffic to the `ui` service on port 80

Apply the HTTPRoute:

```bash hook=exposing-ui hookTimeout=430
$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/exposing-ui/httproute-ui.yaml
```

## Verify the resources

Check that all resources have been created successfully:

```bash
$ kubectl get gatewayclass
NAME      CONTROLLER              ACCEPTED   AGE
aws-alb   gateway.k8s.aws/alb     True       2m
$ kubectl get gateway -n ui
NAME                    CLASS     ADDRESS                                                         PROGRAMMED   AGE
retail-store-gateway    aws-alb   k8s-ui-retailst-xxxxxxxxxx.us-west-2.elb.amazonaws.com          True         2m
$ kubectl get httproute -n ui
NAME       HOSTNAMES   AGE
ui-route               2m
```

Access the UI through the Gateway ALB:

```bash
$ export GATEWAY_URL=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')
$ echo "http://${GATEWAY_URL}"
http://k8s-ui-retailst-xxxxxxxxxx.us-west-2.elb.amazonaws.com
```

You should now be able to access the retail store UI in your browser through the Gateway-provisioned ALB.

<Browser url="http://k8s-ui-retailst-xxxxxxxxxx.us-west-2.elb.amazonaws.com">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>
