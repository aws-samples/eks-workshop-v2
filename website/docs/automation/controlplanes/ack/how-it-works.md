---
title: "How does ACK work?"
sidebar_position: 5
---

:::info
kubectl also provides useful `-oyaml` and `-ojson` flags which extract the full YAML or JSON manifests of the deployment definition, respectively, instead of the formatted output.
:::

The managed ACK controller, running in AWS-managed infrastructure, watches for Kubernetes custom resources specific to DynamoDB, such as `dynamodb.services.k8s.aws.Table`. Based on the configuration in these resources, it makes API calls to the DynamoDB endpoint. As resources are created or modified, the controller updates the status of the custom resources by populating the `Status` fields. For more information about the manifest specifications, refer to the [ACK reference documentation](https://aws-controllers-k8s.github.io/community/reference/).

To see the resource types that ACK makes available in your cluster, you can run:

```bash
$ kubectl get crd
```

This command displays all the Custom Resource Definitions (CRDs) in your cluster. Notice how many `*.services.k8s.aws` resources are listed — the managed ACK capability installs CRDs for a broad range of AWS services (such as S3, RDS, and IAM), not just DynamoDB.

To list only the ACK resource types, filter the output on the `services.k8s.aws` API group:

```bash
$ kubectl get crd | grep services.k8s.aws
accessentries.eks.services.k8s.aws                                    2026-10-31T13:32:34Z
accesspoints.efs.services.k8s.aws                                     2026-10-31T13:33:13Z
accesspoints.s3control.services.k8s.aws                               2026-10-31T13:31:50Z
[...]
tables.dynamodb.services.k8s.aws                                      2026-10-31T13:34:45Z
[...]
```

This is a key difference from a self-managed ACK setup. There, you install a separate controller for each service (for example, the DynamoDB controller on its own), so only that service's CRDs are available in the cluster. With the managed ACK capability, Amazon EKS makes the CRDs for a broad range of ACK-supported services available through a single managed capability — so you can manage many AWS services from Kubernetes without installing and operating a controller for each one.
