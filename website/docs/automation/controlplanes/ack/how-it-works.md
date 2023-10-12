---
title: "How it works"
sidebar_position: 5
---

Each ACK service controller is packaged into a separate container image that is published in a public repository corresponding to an individual ACK service controller. For each AWS service that we wish to provision, resources for the corresponding controller must be installed in the Amazon EKS cluster.

In this section of the workshop, as we will be working with Amazon DynamoDB, the ACK controllers for DynamoDB has been pre-installed in the cluster, running as a deployment in the Cart sample application namespace. To see what's under the hood, lets run the below.

```bash
$ kubectl describe deployment ack-ddb -n carts -oyaml
```

The ```-oyaml``` flag simply extracts the full YAML manifest of the deployment definition instead of the formatted output. Feel free to run the ```describe``` command without the flag as well.

This controller will watch for Kubernetes custom resources for DynamoDB such as `dynamodb.services.k8s.aws.Table` and will make API calls to RDS based on the configuration in those resources created. As resources are created, the controller will feed back status updates to the custom resources in the `Status` fields. For more information about the spec of the manifest, click [here](https://aws-controllers-k8s.github.io/community/reference/)
