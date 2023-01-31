---
title: "How it works"
sidebar_position: 5
---

Each ACK service controller is packaged into a separate container image that is published in a public repository corresponding to an individual ACK service controller. For each AWS service that we wish to provision, resources for the corresponding controller must be installed in the Amazon EKS cluster.

The controllers for both Amazon RDS and Amazon EC2 have been pre-installed in the cluster, each running as a deployment in their respective namespaces. For example, let's take a look at the running RDS controller:

```bash
$ kubectl describe deployment -n ack-rds ack-rds
```

This controller will watch for Kubernetes custom resources for RDS such as `rds.services.k8s.aws.DBInstance` and will make API calls to RDS based on the configuration in those resources created. As resources are created, the controller will feed back status updates to the custom resources in the `Status` fields.
