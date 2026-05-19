# Requirements Document

## Introduction

This module adds a Gateway API section to the EKS Workshop under "Fundamentals > Exposing > Gateway API". It teaches users how to expose Kubernetes services using the Gateway API (the successor to Ingress), demonstrating GatewayClass, Gateway, HTTPRoute resources, path-based routing, and weighted traffic splitting for canary deployments. The module mirrors the structure of the existing Ingress module but showcases Gateway API's superior capabilities.

## Glossary

- **Workshop_Module**: A self-contained section of the EKS Workshop consisting of Terraform infrastructure code, Kubernetes manifests, Docusaurus documentation pages, and automated test hooks
- **Terraform_Config**: The HCL files in `.workshop/terraform/` that provision AWS resources and install Kubernetes add-ons required by the module
- **Manifest_Directory**: The directory under `manifests/modules/exposing/gateway-api/` containing Kubernetes YAML files organized by documentation step
- **Documentation_Page**: A Markdown file under `website/docs/fundamentals/exposing/gateway-api/` rendered by Docusaurus as a workshop page
- **Test_Hook**: A shell script under the `tests/` directory that validates workshop commands execute successfully
- **GatewayClass**: A Kubernetes Gateway API resource that defines which controller manages Gateway resources
- **Gateway**: A Kubernetes Gateway API resource that provisions a load balancer with listeners
- **HTTPRoute**: A Kubernetes Gateway API resource that defines routing rules from a Gateway to backend services
- **Canary_Deployment**: A deployment strategy where a small percentage of traffic is routed to a new version before full rollout
- **LBC**: AWS Load Balancer Controller — the Kubernetes controller that provisions ALBs from Gateway/Ingress resources
- **ExternalDNS**: A Kubernetes add-on that creates DNS records in Route 53 for exposed services

## Requirements

### Requirement 1

**User Story:** As a workshop author, I want Terraform infrastructure that provisions all prerequisites for the Gateway API module, so that learners can start the module with a single `prepare-environment` command.

#### Acceptance Criteria

1. THE Terraform_Config SHALL install AWS Load Balancer Controller with `enableGatewayAPI=true` via the `eks_blueprints_addons` module
2. THE Terraform_Config SHALL install Gateway API CRDs (v1.2.0 standard channel) using a `helm_release` resource for the official `gateway-api` Helm chart from `oci://registry.k8s.io/gateway-api/charts/gateway-api`
3. THE Terraform_Config SHALL create an IAM role for the AWS Load Balancer Controller
4. THE Terraform_Config SHALL create an IAM role for ExternalDNS
5. THE Terraform_Config SHALL create a Route 53 private hosted zone named `retailstore.com`
6. THE Terraform_Config SHALL install ExternalDNS via the `eks_blueprints_addons` module
7. THE Terraform_Config SHALL export environment variables for chart versions and IAM role ARNs matching the pattern used by the ingress module

### Requirement 2

**User Story:** As a workshop learner, I want to expose the UI application using Gateway API resources, so that I can understand how GatewayClass, Gateway, and HTTPRoute work together to provision an ALB.

#### Acceptance Criteria

1. THE Manifest_Directory SHALL contain a `gatewayclass.yaml` file defining a GatewayClass with `controllerName: gateway.k8s.aws/alb`
2. THE Manifest_Directory SHALL contain a `gateway.yaml` file defining a Gateway with an HTTP listener on port 80, `gatewayClassName: aws-alb`, internet-facing scheme, and a `service.beta.kubernetes.io/aws-load-balancer-source-ranges: $INBOUND_CIDRS` annotation
3. THE Manifest_Directory SHALL contain an `httproute-ui.yaml` file defining an HTTPRoute with `PathPrefix: /` routing to the `ui` service on port 8080
4. WHEN the Gateway manifest is applied THEN the Workshop_Module SHALL use `envsubst` to substitute the `$INBOUND_CIDRS` variable before applying
5. THE Documentation_Page SHALL instruct learners to apply each resource individually with `kubectl apply` commands
6. THE Documentation_Page SHALL include verification commands showing `kubectl get gatewayclass`, `kubectl get gateway`, and `kubectl get httproute` output
7. THE Documentation_Page SHALL include a curl command to verify the UI is accessible through the Gateway ALB

### Requirement 3

**User Story:** As a workshop learner, I want to add path-based routing for the Catalog API through the same Gateway, so that I can understand how multiple HTTPRoutes share a single ALB.

#### Acceptance Criteria

1. THE Manifest_Directory SHALL contain an `httproute-catalog.yaml` file defining an HTTPRoute with `PathPrefix: /catalogue` routing to the `catalog` service on port 8080 in the `catalog` namespace
2. THE `httproute-catalog.yaml` SHALL reference the Gateway in the `ui` namespace using a `parentRef` with `namespace: ui`
3. THE Documentation_Page SHALL demonstrate that `/catalogue` returns Catalog API JSON while `/` still returns the UI
4. THE Documentation_Page SHALL explain cross-namespace routing as a Gateway API advantage over Ingress

### Requirement 4

**User Story:** As a workshop learner, I want to perform a canary deployment using weighted traffic splitting, so that I can understand Gateway API's native traffic management capabilities.

#### Acceptance Criteria

1. THE Manifest_Directory SHALL contain a `deployment-ui-v2.yaml` defining a Deployment for `ui-v2` using image `public.ecr.aws/aws-containers/retail-store-sample-ui` with environment variable `RETAIL_UI_THEME=orange` to produce a visually distinct orange-themed UI
2. THE Manifest_Directory SHALL contain a `service-ui-v2.yaml` defining a Service for `ui-v2` on port 8080
3. THE Manifest_Directory SHALL contain an `httproute-ui-canary.yaml` with two `backendRefs` weighted 90 (ui) and 10 (ui-v2)
4. THE Documentation_Page SHALL include a test loop command that sends multiple requests and greps for the theme color (orange) to demonstrate the traffic split
5. THE Documentation_Page SHALL show progressive weight changes: 90/10, then 50/50, then 0/100
6. THE Documentation_Page SHALL explain that weighted traffic splitting is not possible with Kubernetes Ingress

### Requirement 5

**User Story:** As a workshop author, I want automated test hooks that validate each documentation page, so that CI can verify the module works correctly.

#### Acceptance Criteria

1. THE Test_Hook for the exposing-ui page SHALL wait for the Gateway to receive an ALB address and verify HTTP 200 from the ALB endpoint
2. THE Test_Hook for the path-based-routing page SHALL verify that `/catalogue` returns a valid response through the Gateway
3. THE Test_Hook for the canary page SHALL verify that both ui and ui-v2 pods are running and the HTTPRoute is accepted
4. THE Test_Hook suite SHALL include a `hook-suite.sh` that calls `prepare-environment` in its `after()` function

### Requirement 6

**User Story:** As a workshop author, I want a cleanup script that removes all Gateway API resources, so that the module can be torn down cleanly.

#### Acceptance Criteria

1. THE cleanup script SHALL delete all HTTPRoute resources across all namespaces
2. THE cleanup script SHALL delete all Gateway resources across all namespaces
3. THE cleanup script SHALL delete all GatewayClass resources
4. THE cleanup script SHALL uninstall the `gateway-api` Helm chart
5. THE cleanup script SHALL uninstall the `external-dns` Helm chart
6. THE cleanup script SHALL uninstall the `aws-load-balancer-controller` Helm chart

### Requirement 7

**User Story:** As a workshop learner, I want clear documentation with proper Docusaurus formatting, so that I can follow the module in the workshop website.

#### Acceptance Criteria

1. THE index page SHALL have `sidebar_position: 50` and `sidebar_custom_props: { "module": true }`
2. THE index page SHALL include the `prepare-environment exposing/gateway-api` command block
3. THE index page SHALL list what the prepare-environment script provisions
4. EACH Documentation_Page SHALL use `::yaml{file="..."}` directives to reference manifest files
5. EACH Documentation_Page SHALL have appropriate `sidebar_position` values for correct ordering
6. THE Documentation_Page for canary deployment SHALL include a summary comparing Gateway API capabilities to Ingress
