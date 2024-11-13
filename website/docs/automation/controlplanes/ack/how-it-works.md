---
title: "How does ACK work?"
sidebar_position: 5
---

Each AWS Controller for Kubernetes (ACK) is packaged as a separate container image, published in a public repository corresponding to an individual ACK service controller. To provision resources for a specific AWS service, the corresponding controller must be installed in the Amazon EKS cluster. We've already completed this step in the `prepare-environment` phase. Official container images and Helm charts for ACK are available [here](https://gallery.ecr.aws/aws-controllers-k8s).

In this workshop section, we'll be working with Amazon DynamoDB. The ACK controller for DynamoDB has been pre-installed in the cluster, running as a deployment in its own Kubernetes namespace. To examine the deployment details, run the following command:

```bash
$ kubectl describe deployment ack-dynamodb -n ack-dynamodb
```

:::info
kubectl also provides useful `-oyaml` and `-ojson` flags which extract the full YAML or JSON manifests of the deployment definition, respectively, instead of the formatted output.
:::

This controller watches for Kubernetes custom resources specific to DynamoDB, such as `dynamodb.services.k8s.aws.Table`. Based on the configuration in these resources, it makes API calls to the DynamoDB endpoint. As resources are created or modified, the controller updates the status of the custom resources by populating the `Status` fields. For more information about the manifest specifications, refer to the [ACK reference documentation](https://aws-controllers-k8s.github.io/community/reference/).

To gain deeper insight into the objects and API calls the controller listens for, you can run:

```bash
$ kubectl get crd
```

This command will display all the Custom Resource Definitions (CRDs) in your cluster, including those related to ACK and DynamoDB.
