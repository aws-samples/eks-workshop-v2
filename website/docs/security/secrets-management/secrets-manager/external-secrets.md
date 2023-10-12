---
title: "Using External Secrets"
sidebar_position: 64
---

As seen in earlier steps, we have a `Deployment` in the **Catalog** `Namespace` with some credentials declared as environment variables, using values stored in a `Secret` in the same `Namespace`. We could also check that this is not the best approach to store sensitive information, since the secret values are just encoded using *base64*, and can be easily decoded in the command line. We will then modify the **catalog-db** `Deployment` to use the secret stored in AWS Secrets Manager, as the source for the sensitive credentials information.