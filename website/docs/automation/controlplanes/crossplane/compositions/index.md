---
title: "Compositions"
sidebar_position: 30
---

In addition to provisioning individual cloud resources, Crossplane offers a higher abstraction layer called Compositions. Compositions allow users to build opinionated templates for deploying cloud resources. For example, organizations may require certain tags to be present to all AWS resources or add specific encryption keys for all Amazon Simple Storage (S3) buckets. Platform teams can define these self-service API abstractions within Compositions and ensure that all the resources created through these Compositions meet the organization’s requirements.

In this section of the lab we'll see how to package our DynamoDB table as a Crossplane Composition for easier consumption by development teams.
