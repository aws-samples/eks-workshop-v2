---
title: "Compositions"
sidebar_position: 30
---

In addition to provisioning individual cloud resources, Crossplane offers a higher level of abstraction called Compositions. Compositions enable users to create opinionated templates for deploying cloud resources. This feature is particularly useful for organizations that need to enforce specific requirements across their infrastructure, such as:

- Ensuring all AWS resources have certain tags
- Applying specific encryption keys to all Amazon Simple Storage Service (S3) buckets
- Standardizing resource configurations across the organization

With Compositions, platform teams can define self-service API abstractions that guarantee all resources created through these templates meet the organization's requirements. This approach simplifies resource management and ensures consistency across deployments.

In this section of the lab, we'll explore how to package our Amazon DynamoDB table as a Crossplane Composition. This will demonstrate how to create a more easily consumable resource for development teams, while maintaining control over the underlying configuration.

By leveraging Compositions, we'll see how to:

1. Define a standardized template for DynamoDB tables
2. Simplify the resource creation process for developers
3. Ensure compliance with organizational policies and best practices

Through this exercise, you'll gain hands-on experience with Crossplane Compositions and understand their benefits in managing cloud resources within a Kubernetes environment.
