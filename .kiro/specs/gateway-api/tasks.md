# Implementation Plan: Gateway API Workshop Module

## Overview

Implement the Gateway API module for the EKS Workshop following the established patterns of the existing Ingress module. All artifacts are declarative (Terraform, YAML, Markdown, shell scripts). Implementation proceeds bottom-up: infrastructure first, then manifests, then documentation, then test hooks.

## Tasks

- [x] 1. Create Terraform infrastructure
  - [x] 1.1 Create `manifests/modules/exposing/gateway-api/.workshop/terraform/vars.tf`
    - Declare variables: `eks_cluster_id`, `eks_cluster_version`, `cluster_security_group_id`, `addon_context`, `tags`, `resources_precreated`, `load_balancer_controller_chart_version`, `external_dns_chart_version`, `inbound_cidrs`, `gateway_api_chart_version`
    - Match the variable pattern from the ingress module's `vars.tf`
    - Add `gateway_api_chart_version` with default `"1.2.0"`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

  - [x] 1.2 Create `manifests/modules/exposing/gateway-api/.workshop/terraform/main.tf`
    - Add `data "aws_vpc" "this"` block with workshop tags
    - Add `aws_route53_zone` private hosted zone for `retailstore.com`
    - Add `helm_release "gateway_api_crds"` using `oci://registry.k8s.io/gateway-api/charts/gateway-api` chart
    - Add `module "eks_blueprints_addons"` v1.23.0 with LBC (`enableGatewayAPI=true`) and ExternalDNS
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

  - [x] 1.3 Create `manifests/modules/exposing/gateway-api/.workshop/terraform/outputs.tf`
    - Export `LBC_CHART_VERSION`, `LBC_ROLE_ARN`, `DNS_CHART_VERSION`, `DNS_ROLE_ARN` environment variables
    - Match the output pattern from the ingress module
    - _Requirements: 1.7_

- [x] 2. Create Kubernetes manifests for exposing UI
  - [x] 2.1 Create `manifests/modules/exposing/gateway-api/exposing-ui/gatewayclass.yaml`
    - Define GatewayClass `aws-alb` with `controllerName: gateway.k8s.aws/alb`
    - _Requirements: 2.1_

  - [x] 2.2 Create `manifests/modules/exposing/gateway-api/exposing-ui/gateway.yaml`
    - Define Gateway `retail-store-gateway` in namespace `ui`
    - Add annotations: `alb.ingress.kubernetes.io/scheme: internet-facing`, `alb.ingress.kubernetes.io/target-type: ip`, `service.beta.kubernetes.io/aws-load-balancer-source-ranges: $INBOUND_CIDRS`
    - Spec: `gatewayClassName: aws-alb`, listener HTTP on port 80
    - _Requirements: 2.2, 2.4_

  - [x] 2.3 Create `manifests/modules/exposing/gateway-api/exposing-ui/httproute-ui.yaml`
    - Define HTTPRoute `ui-route` in namespace `ui`
    - parentRef to `retail-store-gateway` in `ui` namespace
    - Match `PathPrefix: /`, backendRef to `ui` service port 8080
    - _Requirements: 2.3_

  - [x] 2.4 Create `manifests/modules/exposing/gateway-api/exposing-ui/kustomization.yaml`
    - List all three YAML files as resources
    - _Requirements: 2.1, 2.2, 2.3_

- [x] 3. Create Kubernetes manifests for path-based routing
  - [x] 3.1 Create `manifests/modules/exposing/gateway-api/path-based-routing/httproute-catalog.yaml`
    - Define HTTPRoute `catalog-route` in namespace `catalog`
    - parentRef to `retail-store-gateway` in namespace `ui` (cross-namespace reference)
    - Match `PathPrefix: /catalogue`, backendRef to `catalog` service port 8080
    - _Requirements: 3.1, 3.2_

  - [x] 3.2 Create `manifests/modules/exposing/gateway-api/path-based-routing/kustomization.yaml`
    - List httproute-catalog.yaml as resource
    - _Requirements: 3.1_

- [x] 4. Create Kubernetes manifests for canary deployment
  - [x] 4.1 Create `manifests/modules/exposing/gateway-api/canary/deployment-ui-v2.yaml`
    - Define Deployment `ui-v2` in namespace `ui`
    - Use image `public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1`
    - Set env var `RETAIL_UI_THEME=orange` to produce a visually distinct orange-themed UI
    - Labels: `app.kubernetes.io/name: ui`, `app.kubernetes.io/version: v2`
    - _Requirements: 4.1_

  - [x] 4.2 Create `manifests/modules/exposing/gateway-api/canary/service-ui-v2.yaml`
    - Define Service `ui-v2` in namespace `ui` selecting pods with version `v2`
    - Port 8080 targeting 8080
    - _Requirements: 4.2_

  - [x] 4.3 Create `manifests/modules/exposing/gateway-api/canary/httproute-ui-canary.yaml`
    - Define HTTPRoute `ui-route` with two backendRefs: `ui` weight 90, `ui-v2` weight 10
    - _Requirements: 4.3_

  - [x] 4.4 Create `manifests/modules/exposing/gateway-api/canary/httproute-canary-50-50.yaml`
    - Same as canary route but weights 50/50
    - _Requirements: 4.5_

  - [x] 4.5 Create `manifests/modules/exposing/gateway-api/canary/httproute-canary-0-100.yaml`
    - Same as canary route but weights 0/100 (full cutover)
    - _Requirements: 4.5_

  - [x] 4.6 Create `manifests/modules/exposing/gateway-api/canary/kustomization.yaml`
    - List deployment, service, and initial canary httproute as resources
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 5. Checkpoint - Verify all manifests and Terraform
  - Ensure all YAML files are valid and all Terraform files are syntactically correct, ask the user if questions arise.

- [x] 6. Create the cleanup script
  - [x] 6.1 Create `manifests/modules/exposing/gateway-api/.workshop/cleanup.sh`
    - Delete all HTTPRoute, Gateway, GatewayClass resources with `--ignore-not-found`
    - Call `uninstall-helm-chart gateway-api gateway-system`
    - Call `uninstall-helm-chart external-dns external-dns`
    - Call `uninstall-helm-chart aws-load-balancer-controller kube-system`
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 7. Create documentation - index page
  - [x] 7.1 Create `website/docs/fundamentals/exposing/gateway-api/index.md`
    - Frontmatter: title "Gateway API", sidebar_position 50, sidebar_custom_props module true
    - Include `prepare-environment exposing/gateway-api` command block
    - List what the script provisions (LBC with Gateway API support, Gateway API CRDs, IAM roles, Route 53 zone)
    - Introduction text explaining Gateway API vs Ingress, role-oriented design
    - Overview of what the module covers (3 steps)
    - _Requirements: 7.1, 7.2, 7.3_

- [x] 8. Create documentation - exposing UI page
  - [x] 8.1 Create `website/docs/fundamentals/exposing/gateway-api/exposing-ui.md`
    - Frontmatter: title "Exposing the UI", sidebar_position 10
    - Step 1: Create GatewayClass with `::yaml` directive and `kubectl apply` command
    - Step 2: Create Gateway with `::yaml` directive and `cat | envsubst | kubectl apply` command
    - Step 3: Create HTTPRoute with `::yaml` directive and `kubectl apply` command
    - Step 4: Verify with `kubectl get` commands and curl test
    - Include hook reference: `hook=exposing-ui hookTimeout=430`
    - _Requirements: 2.4, 2.5, 2.6, 2.7, 7.4, 7.5_

- [x] 9. Create documentation - path-based routing page
  - [x] 9.1 Create `website/docs/fundamentals/exposing/gateway-api/path-based-routing.md`
    - Frontmatter: title "Path-Based Routing", sidebar_position 20
    - Introduction explaining multi-service routing through same Gateway
    - Show current state (only UI route exists)
    - Create Catalog HTTPRoute with `::yaml` directive and `kubectl apply`
    - Verify both routes work with curl commands
    - Explain cross-namespace routing advantage
    - Include hook reference: `hook=path-routing hookTimeout=180`
    - _Requirements: 3.3, 3.4, 7.4, 7.5_

- [x] 10. Create documentation - canary deployment page
  - [x] 10.1 Create `website/docs/fundamentals/exposing/gateway-api/canary.md`
    - Frontmatter: title "Canary Deployment", sidebar_position 30
    - Introduction explaining weighted traffic splitting
    - Step 1: Deploy ui-v2 (deployment + service) with `::yaml` directives
    - Step 2: Apply 90/10 canary HTTPRoute
    - Step 3: Test loop with `for i in $(seq 1 20); do curl -s ... | grep "version"; done`
    - Step 4: Update to 50/50 weights
    - Step 5: Complete rollout to 0/100
    - Summary section with Gateway API vs Ingress comparison table
    - Include hook reference: `hook=canary hookTimeout=180`
    - _Requirements: 4.4, 4.5, 4.6, 7.4, 7.5, 7.6_

- [x] 11. Create test hooks
  - [x] 11.1 Create `website/docs/fundamentals/exposing/gateway-api/tests/hook-suite.sh`
    - Standard pattern: `set -e`, `before()` noop, `after()` calls `prepare-environment`
    - _Requirements: 5.4_

  - [x] 11.2 Create `website/docs/fundamentals/exposing/gateway-api/tests/hook-exposing-ui.sh`
    - Wait for Gateway to get ALB address
    - Poll ALB endpoint until HTTP 200 with 400s timeout
    - _Requirements: 5.1_

  - [x] 11.3 Create `website/docs/fundamentals/exposing/gateway-api/tests/hook-path-routing.sh`
    - Get Gateway endpoint, curl `/catalogue` until HTTP 200
    - _Requirements: 5.2_

  - [x] 11.4 Create `website/docs/fundamentals/exposing/gateway-api/tests/hook-canary.sh`
    - Verify ui-v2 pods are Ready
    - Verify HTTPRoute is Accepted
    - _Requirements: 5.3_

- [x] 12. Final checkpoint - Review all artifacts
  - Ensure all files are consistent, cross-references are correct, and the module follows established workshop patterns. Ask the user if questions arise.

## Notes

- No property-based tests are applicable — all artifacts are declarative (Terraform, YAML, Markdown, shell)
- Test hooks serve as integration tests and run against a live EKS cluster in CI
- Each documentation page applies manifests individually for pedagogical step-by-step learning
- The Gateway manifest requires `envsubst` due to the `$INBOUND_CIDRS` annotation
- Manifests are organized in step directories with kustomization.yaml for reference, but docs show individual kubectl apply commands
