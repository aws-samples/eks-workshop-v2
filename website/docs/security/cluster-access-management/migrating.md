---
title: "Migrating from aws-auth identity mapping"
sidebar_position: 20
---

Customers who already use Amazon EKS may be familiar with the `aws-auth` ConfigMap mechanism for managing IAM principal access to clusters. The workshop cluster uses the `API` authentication mode, so it relies only on access entries and there is no `aws-auth` ConfigMap to migrate.

To migrate your own clusters from the `aws-auth` ConfigMap to access entries, follow [Migrating existing aws-auth ConfigMap entries to access entries](https://docs.aws.amazon.com/eks/latest/userguide/migrating-access-entries.html) in the Amazon EKS User Guide. If you manage your clusters with `eksctl`, also see [EKS access entries](https://docs.aws.amazon.com/eks/latest/eksctl/access-entries.html) in the `eksctl` documentation.
