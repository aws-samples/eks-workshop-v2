---
title: "How does ACK work?"
sidebar_position: 5
---

:::info
kubectl also provides useful `-oyaml` and `-ojson` flags which extract the full YAML or JSON manifests of the deployment definition, respectively, instead of the formatted output.
:::

This controller watches for Kubernetes custom resources specific to DynamoDB, such as `dynamodb.services.k8s.aws.Table`. Based on the configuration in these resources, it makes API calls to the DynamoDB endpoint. As resources are created or modified, the controller updates the status of the custom resources by populating the `Status` fields. For more information about the manifest specifications, refer to the [ACK reference documentation](https://aws-controllers-k8s.github.io/community/reference/).

To gain deeper insight into the objects and API calls the controller listens for, you can run:

```bash
$ kubectl get crd
```

This command will display all the Custom Resource Definitions (CRDs) in your cluster, including those related to ACK and DynamoDB.
