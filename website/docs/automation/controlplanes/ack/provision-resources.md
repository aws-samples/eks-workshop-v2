---
title: "Provisioning ACK Resources"
sidebar_position: 5
---

By default the **Carts** component in the sample application uses a DynamoDB local instance running as a pod in the EKS cluster called `carts-dynamodb`. In this section of the lab, we'll provision an Amazon DynamoDB cloud based table for our application using Kubernetes custom resources and point the **Carts** deployment to use the newly provisioned DynamoDB table instead of the local copy.

![ACK reconciler concept](./assets/ack-desired-current-ddb.webp)

The AWS Java SDK in the **Carts** component is able to use IAM Roles to interact with AWS services which means that we do not need to pass credentials, thus reducing the attack surface. In the EKS context, IRSA allows us to define per pod IAM Roles for applications to consume. To leverage IRSA, we first need to:

- Create a Kubernetes Service Account in the Carts namespace
- Create an IAM Policy with necessary DynamoDB permissions
- Create an IAM Role in AWS with the above permissions
- Map the Service Account to use the IAM role using Annotations in the Service Account definition.

Fortunately, we have a handy one-liner to help with this process. Run the below:

```bash
$ eksctl create iamserviceaccount --name carts-ack \
  --namespace carts --cluster $EKS_CLUSTER_NAME \
  --role-name ${EKS_CLUSTER_NAME}-carts-ack \
  --attach-policy-arn $DYNAMODB_POLICY_ARN --approve
2023-10-31 16:20:46 [i]  1 iamserviceaccount (carts/carts-ack) was included (based on the include/exclude rules)
2023-10-31 16:20:46 [i]  1 task: {
    2 sequential sub-tasks: {
        create IAM role for serviceaccount "carts/carts-ack",
        create serviceaccount "carts/carts-ack",
    } }2023-10-31 16:20:46 [ℹ]  building iamserviceaccount stack "eksctl-eks-workshop-addon-iamserviceaccount-carts-carts-ack"
2023-10-31 16:20:46 [i]  deploying stack "eksctl-eks-workshop-addon-iamserviceaccount-carts-carts-ack"
2023-10-31 16:20:47 [i]  waiting for CloudFormation stack "eksctl-eks-workshop-addon-iamserviceaccount-carts-carts-ack"
2023-10-31 16:21:17 [i]  waiting for CloudFormation stack "eksctl-eks-workshop-addon-iamserviceaccount-carts-carts-ack"
2023-10-31 16:21:17 [i]  created serviceaccount "carts/carts-ack"
```

`eksctl` provisions a CloudFormation stack to help manage these resources which can be seen in the output above.

To learn more about how IRSA works, go [here](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).

---

Now, let's explore how we'll create the DynamoDB Table via a Kubernetes manifest

```file
manifests/modules/automation/controlplanes/ack/dynamodb/dynamodb-create.yaml
```

:::info

Astute readers will notice the YAML Spec to be similar to the API endpoints and calls for DynamoDB such as `tableName` and `attributeDefinitions`.

:::

Next, we will need to update the regional endpoint for DynamoDB within the Configmap used by the Kustomization to update the **Carts** deployment.

```file
manifests/modules/automation/controlplanes/ack/dynamodb/dynamodb-ack-configmap.yaml
```

Using the `envsubst` utility, we will rewrite the environment variable AWS_REGION into the manifest and apply all the updates to the cluster. Run the below

```bash wait=10
$ kubectl kustomize ~/environment/eks-workshop/modules/automation/controlplanes/ack/dynamodb \
  | envsubst | kubectl apply -f-
namespace/carts unchanged
serviceaccount/carts unchanged
configmap/carts unchanged
configmap/carts-ack created
service/carts unchanged
service/carts-dynamodb unchanged
deployment.apps/carts configured
deployment.apps/carts-dynamodb unchanged
table.dynamodb.services.k8s.aws/items created
$ kubectl rollout status -n carts deployment/carts --timeout=120s
```

:::info
This command 'builds' the manifests using the kubectl kustomize command, pipes it to `envsubst` and then to kubectl apply. This makes it easy to template manifests and populate them at run-time.
:::

The ACK controllers in the cluster will react to these new resources and provision the AWS infrastructure we have expressed with the manifests earlier. Lets check if ACK created the table by running

```bash
$ kubectl wait table.dynamodb.services.k8s.aws items -n carts --for=condition=ACK.ResourceSynced --timeout=15m
table.dynamodb.services.k8s.aws/items condition met
$ kubectl get table.dynamodb.services.k8s.aws items -n carts -ojson | yq '.status."tableStatus"'
ACTIVE
```

And now to check if the Table has been created using the AWS CLI, run

```bash
$ aws dynamodb list-tables

{
    "TableNames": [
        "eks-workshop-carts-ack"
    ]
}
```

This output tells us that the new table has been created!
