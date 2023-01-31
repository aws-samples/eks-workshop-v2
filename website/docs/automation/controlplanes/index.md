---
title: "Control Planes"
sidebar_position: 3
weight: 30
---

Control Plane frameworks allow you to manage AWS resources directly from Kubernetes using the standard Kubernetes CLI, `kubectl`. It does so by modeling AWS managed services as [Custom Resource Definitions (CRDs)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) in Kubernetes and applying those definitions to your cluster. This means that a developer can model their entire application architecture from container to AWS managed services, backing it from a single YAML manifest. We anticipate that the Control Planes will help reduce the time it takes to create new applications, and assist in keeping cloud native solutions in the desired state.

Two popular open source projects for Control Planes are [AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/) and CNCF incubating project [Crossplane](https://www.crossplane.io/), both of which support AWS Services. This workshop module focus on these two projects.
