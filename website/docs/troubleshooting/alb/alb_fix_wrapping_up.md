---
title: "Wrapping it up"
sidebar_position: 33
---

## Understanding the AWS Load Balancer Controller

Let's review what we learned about how the AWS Load Balancer Controller works with Application Load Balancers (ALBs). Understanding this architecture helps with future troubleshooting.

### Core Components and Flow

1. **Controller Operation**
   * The controller continuously watches for ingress events from the Kubernetes API server
   * When it detects qualifying ingress resources, it begins creating corresponding AWS resources
   * The controller manages the full lifecycle of these AWS resources

2. **Application Load Balancer (ALB)**
   * An ALB is created for each ingress resource
   * Can be configured as internet-facing or internal
   * Subnet placement is controlled through annotations
   * Requires proper IAM permissions for creation and management

3. **Target Groups**
   * Created for each unique Kubernetes service defined in the ingress
   * Support IP-mode targeting for direct pod registration
   * Health checks are configurable via annotations
   * Multiple target groups can be used for different services

4. **Listeners**
   * Created for each port specified in ingress annotations
   * Default to standard ports (80/443) when not specified
   * Support SSL/TLS certificate attachment
   * Can be configured for HTTP/HTTPS traffic

5. **Rules**
   * Created based on path specifications in ingress resources
   * Direct traffic to appropriate target groups
   * Support path-based and host-based routing
   * Can be prioritized for complex routing scenarios

### Common Troubleshooting Areas

Through this module, we encountered and fixed several typical issues:

1. **Subnet Configuration**
   * Public subnets require the `kubernetes.io/role/elb=1` tag
   * Private subnets require the `kubernetes.io/role/internal-elb=1` tag
   * Subnets must be properly associated with route tables

2. **IAM Permissions**
   * Service account requires appropriate IAM role
   * Role must have necessary permissions for ALB operations
   * Common permissions include creating/modifying load balancers and target groups

3. **Service Configuration**
   * Service selectors must match pod labels exactly
   * Service ports must align with container ports
   * Service name must match ingress backend configuration

### Best Practices

When working with the AWS Load Balancer Controller:

* Always verify subnet tags before creating internet-facing ALBs
* Use explicit annotations to control ALB behavior
* Monitor controller logs for troubleshooting
* Verify service endpoint registration
* Use meaningful labels for services and pods
* Document custom configurations

:::tip
The [AWS Load Balancer Controller documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/) is an excellent resource for advanced configurations and troubleshooting.
:::

