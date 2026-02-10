---
title: "App of Apps"
chapter: true
sidebar_position: 100
---

When managing complex application stacks composed of multiple microservices, manually creating and maintaining individual Argo CD applications can become operationally challenging. The App of Apps pattern addresses this complexity by enabling you to manage multiple applications through a single parent application.

The App of Apps pattern leverages Argo CD's declarative approach by creating one parent Argo CD application that contains manifests defining other Argo CD applications. This creates a hierarchical structure where the parent application monitors a Git repository containing application definitions, automatically creating, updating, or deleting child applications based on changes to these manifests.

This pattern provides several operational advantages:

- **Centralized Management**: All application definitions are maintained in a single Git repository, providing a unified view of your deployment landscape
- **Environment Consistency**: Ensures consistent application deployment across multiple environments by maintaining declarative configuration
- **Operational Efficiency**: Reduces manual overhead and potential for configuration drift
- **GitOps Compliance**: Maintains the principle of Git as the single source of truth for your application portfolio

The workflow operates as follows: the parent application continuously monitors a Git repository containing Argo CD Application manifests. When changes are committed to the repository, Argo CD detects these modifications and automatically manages the lifecycle of child applications. Each child application then synchronizes its resources from its respective source repository.

A typical repository structure might look like this:

```text
app-of-apps/
├── parent-app.yaml          # The parent application
└── applications/            # Individual app definitions
    ├── frontend-app.yaml
    ├── backend-app.yaml
    └── database-app.yaml
```

This pattern is particularly effective for bootstrapping entire environments and maintaining consistency across multiple clusters. Rather than manually configuring individual applications through the Argo CD UI, you can declaratively define your entire application portfolio and allow Argo CD to manage the deployment lifecycle automatically.
