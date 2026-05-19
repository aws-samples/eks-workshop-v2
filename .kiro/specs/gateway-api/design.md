# Design Document: Gateway API Workshop Module

## Overview

This module adds a complete Gateway API section to the EKS Workshop under "Fundamentals > Exposing > Gateway API". It follows the established patterns of the existing Ingress module but demonstrates Gateway API's role-oriented resource model (GatewayClass → Gateway → HTTPRoute), cross-namespace routing, and native weighted traffic splitting for canary deployments.

The module consists of:
- Terraform infrastructure provisioning (LBC, Gateway API CRDs, ExternalDNS, Route 53)
- Kubernetes manifests organized by documentation step
- Four Docusaurus documentation pages (index, exposing-ui, path-based-routing, canary)
- Automated test hooks for CI validation
- A cleanup script for teardown

## Architecture

### Directory Structure

```
manifests/modules/exposing/gateway-api/
├── .workshop/
│   ├── terraform/
│   │   ├── main.tf          # LBC, ExternalDNS, Route53, Gateway API CRDs
│   │   ├── outputs.tf       # Environment variable exports
│   │   └── vars.tf          # Variable declarations
│   └── cleanup.sh           # Module teardown script
├── exposing-ui/
│   ├── gatewayclass.yaml
│   ├── gateway.yaml
│   ├── httproute-ui.yaml
│   └── kustomization.yaml
├── path-based-routing/
│   ├── httproute-catalog.yaml
│   └── kustomization.yaml
└── canary/
    ├── deployment-ui-v2.yaml
    ├── service-ui-v2.yaml
    ├── httproute-ui-canary.yaml
    ├── httproute-canary-50-50.yaml
    ├── httproute-canary-0-100.yaml
    └── kustomization.yaml

website/docs/fundamentals/exposing/gateway-api/
├── index.md                  # Module intro + prepare-environment
├── exposing-ui.md            # GatewayClass + Gateway + HTTPRoute
├── path-based-routing.md     # Catalog HTTPRoute
├── canary.md                 # Weighted traffic splitting
└── tests/
    ├── hook-suite.sh
    ├── hook-exposing-ui.sh
    ├── hook-path-routing.sh
    └── hook-canary.sh
```

### Resource Flow

```
GatewayClass (aws-alb)
    └── Gateway (retail-store-gateway, namespace: ui)
            ├── HTTPRoute (ui-route, namespace: ui)
            │       └── Service: ui:8080
            ├── HTTPRoute (catalog-route, namespace: catalog)
            │       └── Service: catalog:8080
            └── HTTPRoute (ui-canary, namespace: ui)  [replaces ui-route]
                    ├── Service: ui:8080 (weight: 90)
                    └── Service: ui-v2:8080 (weight: 10)
```

## Components

### 1. Terraform Infrastructure (`main.tf`)

```hcl
data "aws_vpc" "this" {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

resource "aws_route53_zone" "private_zone" {
  name    = "retailstore.com"
  comment = "Private hosted zone for EKS Workshop use"
  vpc {
    vpc_id = data.aws_vpc.this.id
  }
  force_destroy = true
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.addon_context.eks_cluster_id
  }
}

resource "helm_release" "gateway_api_crds" {
  name             = "gateway-api"
  repository       = "oci://registry.k8s.io/gateway-api/charts"
  chart            = "gateway-api"
  version          = "1.2.0"
  namespace        = "gateway-system"
  create_namespace = true
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.23.0"

  cluster_name      = var.addon_context.eks_cluster_id
  cluster_endpoint  = var.addon_context.aws_eks_cluster_endpoint
  cluster_version   = var.eks_cluster_version
  oidc_provider_arn = var.addon_context.eks_oidc_provider_arn

  enable_external_dns            = true
  external_dns_route53_zone_arns = [aws_route53_zone.private_zone.arn]
  external_dns = {
    create_role = true
    role_name   = "${var.addon_context.eks_cluster_id}-external-dns"
    policy_name = "${var.addon_context.eks_cluster_id}-external-dns"
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    role_name   = "${var.addon_context.eks_cluster_id}-alb-controller"
    policy_name = "${var.addon_context.eks_cluster_id}-alb-controller"
    set = [
      {
        name  = "enableGatewayAPI"
        value = "true"
      }
    ]
  }

  create_kubernetes_resources = false
  observability_tag           = null
}
```

### 2. Kubernetes Manifests

#### GatewayClass (`exposing-ui/gatewayclass.yaml`)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: aws-alb
spec:
  controllerName: gateway.k8s.aws/alb
```

#### Gateway (`exposing-ui/gateway.yaml`)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: retail-store-gateway
  namespace: ui
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-source-ranges: $INBOUND_CIDRS
spec:
  gatewayClassName: aws-alb
  listeners:
    - name: http
      protocol: HTTP
      port: 80
```

#### HTTPRoute for UI (`exposing-ui/httproute-ui.yaml`)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ui-route
  namespace: ui
spec:
  parentRefs:
    - name: retail-store-gateway
      namespace: ui
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: ui
          port: 8080
```

#### HTTPRoute for Catalog (`path-based-routing/httproute-catalog.yaml`)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: catalog-route
  namespace: catalog
spec:
  parentRefs:
    - name: retail-store-gateway
      namespace: ui
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /catalogue
      backendRefs:
        - name: catalog
          port: 8080
```

#### UI v2 Deployment (`canary/deployment-ui-v2.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ui-v2
  namespace: ui
  labels:
    app.kubernetes.io/name: ui
    app.kubernetes.io/version: v2
    app.kubernetes.io/component: service
    app.kubernetes.io/created-by: eks-workshop
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: ui
      app.kubernetes.io/version: v2
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ui
        app.kubernetes.io/version: v2
    spec:
      containers:
        - name: ui
          image: public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1
          ports:
            - containerPort: 8080
              protocol: TCP
          env:
            - name: RETAIL_UI_THEME
              value: "orange"
```

#### UI v2 Service (`canary/service-ui-v2.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ui-v2
  namespace: ui
  labels:
    app.kubernetes.io/name: ui
    app.kubernetes.io/version: v2
    app.kubernetes.io/created-by: eks-workshop
spec:
  selector:
    app.kubernetes.io/name: ui
    app.kubernetes.io/version: v2
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
```

#### Canary HTTPRoute 90/10 (`canary/httproute-ui-canary.yaml`)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ui-route
  namespace: ui
spec:
  parentRefs:
    - name: retail-store-gateway
      namespace: ui
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: ui
          port: 8080
          weight: 90
        - name: ui-v2
          port: 8080
          weight: 10
```

#### Canary HTTPRoute 50/50 (`canary/httproute-canary-50-50.yaml`)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ui-route
  namespace: ui
spec:
  parentRefs:
    - name: retail-store-gateway
      namespace: ui
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: ui
          port: 8080
          weight: 50
        - name: ui-v2
          port: 8080
          weight: 50
```

#### Canary HTTPRoute 0/100 (`canary/httproute-canary-0-100.yaml`)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ui-route
  namespace: ui
spec:
  parentRefs:
    - name: retail-store-gateway
      namespace: ui
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: ui
          port: 8080
          weight: 0
        - name: ui-v2
          port: 8080
          weight: 100
```

### 3. Test Hooks

#### `hook-exposing-ui.sh`

```bash
set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 20

  export gateway_endpoint=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')

  if [ -z "$gateway_endpoint" ]; then
    >&2 echo "Failed to retrieve address from Gateway"
    exit 1
  fi

  EXIT_CODE=0

  timeout -s TERM 400 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${gateway_endpoint}/home)" != "200" ]];
    do sleep 20;
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Gateway ALB did not become available after 400 seconds"
    exit 1
  fi
}

"$@"
```

#### `hook-path-routing.sh`

```bash
set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  export gateway_endpoint=$(kubectl get gateway retail-store-gateway -n ui -o jsonpath='{.status.addresses[0].value}')

  EXIT_CODE=0

  timeout -s TERM 120 bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${gateway_endpoint}/catalogue)" != "200" ]];
    do sleep 10;
    done' || EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    >&2 echo "Catalog route did not become available"
    exit 1
  fi
}

"$@"
```

#### `hook-canary.sh`

```bash
set -Eeuo pipefail

before() {
  echo "noop"
}

after() {
  sleep 10

  # Verify ui-v2 pods are running
  kubectl wait --for=condition=Ready pods -l app.kubernetes.io/version=v2 -n ui --timeout=120s

  # Verify HTTPRoute is accepted
  kubectl get httproute ui-route -n ui -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' | grep -q "True"
}

"$@"
```

#### `hook-suite.sh`

```bash
set -e

before() {
  echo "noop"
}

after() {
  prepare-environment
}

"$@"
```

### 4. Cleanup Script (`cleanup.sh`)

```bash
#!/bin/bash

set -e

kubectl delete httproute --all -A --ignore-not-found
kubectl delete gateway --all -A --ignore-not-found
kubectl delete gatewayclass --all --ignore-not-found

uninstall-helm-chart gateway-api gateway-system

uninstall-helm-chart external-dns external-dns

uninstall-helm-chart aws-load-balancer-controller kube-system
```

### 5. Documentation Pages

#### Page Structure

| File | sidebar_position | Title | Content |
|------|-----------------|-------|---------|
| `index.md` | 50 | Gateway API | Module intro, prepare-environment, overview |
| `exposing-ui.md` | 10 | Exposing the UI | GatewayClass + Gateway + HTTPRoute creation |
| `path-based-routing.md` | 20 | Path-Based Routing | Catalog HTTPRoute, cross-namespace |
| `canary.md` | 30 | Canary Deployment | Weighted splitting, progressive rollout |

#### Documentation Conventions

- Use `::yaml{file="manifests/modules/exposing/gateway-api/..."}` for manifest references
- Use `$ kubectl apply -f ~/environment/eks-workshop/modules/exposing/gateway-api/...` for individual file applies
- Use `envsubst` pipe for gateway.yaml: `cat ... | envsubst | kubectl apply -f -`
- Include `hook=<hook-name>` and `hookTimeout=<seconds>` on commands that need test validation
- Use `timeout=<seconds>` on commands that may take time

## Error Handling

- Gateway manifest requires `$INBOUND_CIDRS` environment variable; `envsubst` handles substitution
- Test hooks use `timeout` with fallback exit codes to handle ALB provisioning delays
- Cleanup script uses `--ignore-not-found` to handle idempotent teardown
- Terraform uses `force_destroy = true` on Route 53 zone for clean teardown

## Correctness Properties

*This module consists entirely of declarative infrastructure (Terraform HCL), Kubernetes manifests (YAML), documentation (Markdown), and shell scripts. There is no application logic, data transformation, or algorithmic code suitable for property-based testing. All acceptance criteria are validated through integration tests (test hooks running against a live cluster) and static content verification.*

No property-based tests are applicable for this module.
