---
title: Package Management
sidebar_position: 70
description: "Learn about Kubernetes package management and deployment tools - Kustomize and Helm."
---

# Package Management

As Kubernetes applications grow in complexity, managing multiple YAML files across different environments becomes challenging. **Package management tools** help you organize, customize, and deploy applications more efficiently.

Kubernetes offers two primary approaches to solve these challenges:

## Kustomize - Configuration Management
**Kustomize** uses a patch-based approach to customize Kubernetes YAML files:

- **Template-free**: Works with standard Kubernetes YAML
- **Overlay-based**: Apply patches to base configurations  
- **Built into kubectl**: Native integration with `kubectl apply -k`
- **GitOps friendly**: Excellent for declarative workflows

**Best for**: Teams preferring pure YAML, simple customizations, and GitOps workflows.

## Helm - Package Manager
**Helm** uses templates to generate Kubernetes manifests:

- **Templating**: Go templates with variables and functions
- **Packaging**: Bundle applications into reusable charts
- **Release management**: Install, upgrade, and rollback applications
- **Large ecosystem**: Thousands of pre-built charts available

**Best for**: Complex applications, sharing across teams, and leveraging existing charts.

## Comparison

| Feature | Kustomize | Helm |
|---------|-----------|------|
| **Approach** | Patch-based | Template-based |
| **Learning Curve** | Gentler (standard YAML) | Steeper (template syntax) |
| **Release Management** | Basic (via kubectl) | Advanced (install/upgrade/rollback) |
| **Ecosystem** | Growing adoption | Mature with large chart library |
| **GitOps** | Excellent | Good (with additional tools) |

## When to Use Which?

**Choose Kustomize when:**
- You prefer standard Kubernetes YAML
- Your customization needs are straightforward  
- You want tight kubectl integration

**Choose Helm when:**
- You need complex templating and conditional logic
- You're distributing applications across teams
- You want sophisticated release management

Many teams use both tools together - Helm for complex third-party applications and Kustomize for simple internal services.

## Explore Package Management

- **[Kustomize](./kustomize)** - Learn patch-based configuration management
- **[Helm](./helm)** - Master template-based package management