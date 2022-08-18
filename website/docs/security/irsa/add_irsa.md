---
title: "Applying IRSA"
sidebar_position: 40
hide_table_of_contents: true
---

A IAM role which provides the required permissions to access the DynamoDB table has been created for you. You can view the policy like so:

```bash test=false
aws iam get-policy-version \
  --version-id v1 --policy-arn \
  arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${EKS_CLUSTER_NAME}-carts-dynamo
```

The role has also been configured with the appropriate trust relationship for our EKS cluster, which can been viewed like so:

```bash test=false
aws iam get-role --role-name ${EKS_CLUSTER_NAME}-carts-dynamo
```

All thats left to us is to re-configure the `ServiceAccount` object used by the `carts` service to give it with the required annotation so that IRSA provides the correct Pods with the IAM role above.

```kustomization
security/irsa/service-account/carts-serviceAccount.yaml
ServiceAccount/carts
```

Run Kustomize to apply this change:

```bash
kubectl apply -k /workspace/modules/security/irsa/service-account
```

With the `ServiceAccount` updated now we just need to recycle the `carts` Pod so it picks up the new `ServiceAccount`:

```bash hook=enable-irsa
kubectl delete pod -n carts \
  -l app.kubernetes.io/component=service
```

Now access the web store again and navigate to the shopping cart. Success!