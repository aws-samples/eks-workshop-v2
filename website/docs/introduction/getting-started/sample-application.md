---
title: Sample application
sidebar_position: 10
---

# Sample Application Architecture

The EKS workshop uses a retail store application that demonstrates real-world microservices patterns. This application will help you understand how the Kubernetes concepts you learned work together in practice.

## Application Overview

The sample application models a simple web store where customers can browse a catalog, add items to their cart, and complete orders through the checkout process.

<Browser url="-">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

## Architecture

The application follows a microservices architecture with several independent components:

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

| Component | Description | Kubernetes Resources |
| --------- | ----------- | -------------------- |
| **UI** | Front-end user interface that aggregates API calls to other services | Deployment, Service, ConfigMap |
| **Catalog** | API for product listings and details | Deployment, Service, ConfigMap, Secret |
| **Cart** | API for customer shopping carts | Deployment, Service, ConfigMap |
| **Checkout** | API to orchestrate the checkout process | Deployment, Service, ConfigMap |
| **Orders** | API to receive and process customer orders | Deployment, Service, ConfigMap, Secret |

## How It Maps to Kubernetes Concepts

Now that you understand Kubernetes fundamentals, let's see how they apply to this application:

### Pods and Deployments
- Each microservice runs as a **Deployment** managing multiple **Pod** replicas
- Each Pod contains one container running the microservice
- Deployments handle scaling, updates, and Pod replacement

### Services
- Each microservice has a **Service** that provides a stable endpoint
- Services use **ClusterIP** type for internal communication
- The UI service may use **LoadBalancer** for external access

### Configuration
- **ConfigMaps** store non-sensitive configuration like API endpoints
- **Secrets** store sensitive data like database passwords
- Configuration is injected as environment variables or mounted files

### Namespaces
- Each microservice runs in its own **Namespace** for organization
- Namespaces provide logical separation and resource isolation

## Data Storage

The application includes several data stores:

- **MySQL** - Used by the catalog service for product data
- **DynamoDB** - Used by the cart service (simulated with local DynamoDB)
- **PostgreSQL** - Used by the orders service for order data
- **Redis** - Used by the checkout service for session data

These databases also run as Kubernetes workloads using **StatefulSets** for persistent storage.

## Container Images

All components are packaged as container images and published to Amazon ECR Public:

| Component | ECR Public Repository |
| --------- | -------------------- |
| UI | [retail-store-sample-ui](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui) |
| Catalog | [retail-store-sample-catalog](https://gallery.ecr.aws/aws-containers/retail-store-sample-catalog) |
| Cart | [retail-store-sample-cart](https://gallery.ecr.aws/aws-containers/retail-store-sample-cart) |
| Checkout | [retail-store-sample-checkout](https://gallery.ecr.aws/aws-containers/retail-store-sample-checkout) |
| Orders | [retail-store-sample-orders](https://gallery.ecr.aws/aws-containers/retail-store-sample-orders) |

## Deployment Strategy

We'll deploy this application using **Kustomize**, which allows us to:
- Organize manifests by component
- Apply consistent labels and configurations
- Make environment-specific customizations
- Deploy multiple components together

## Real-World Patterns

This application demonstrates several important patterns:

### Microservices Communication
- Services communicate via HTTP APIs
- Each service has its own data store
- Loose coupling between components

### Configuration Management
- Environment-specific settings in ConfigMaps
- Sensitive data in Secrets
- Configuration injected at runtime

### Scalability
- Each service can scale independently
- Stateless services for horizontal scaling
- Persistent storage for databases

### Observability
- Health check endpoints for liveness/readiness probes
- Structured logging for troubleshooting
- Metrics endpoints for monitoring

## Source Code

You can explore the full source code on [GitHub](https://github.com/aws-containers/retail-store-sample-app) to understand how the application is built and containerized.

## What's Next?

Now that you understand the application architecture, let's start deploying it step by step in [Deploying Components](./deploying-components). We'll begin with a single service to see how your Kubernetes knowledge applies in practice.