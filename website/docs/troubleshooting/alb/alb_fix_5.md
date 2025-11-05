---
title: "IAM Policy Issue"
sidebar_position: 31
---

In this section, we'll address an issue where the AWS Load Balancer Controller lacks the necessary IAM permissions to create and manage Application Load Balancers. We'll walk through identifying and fixing the IAM policy configuration.

### Step 1: Identify the Service Account Role

First, let's examine the service account used by the Load Balancer Controller. The controller uses IAM Roles for Service Accounts (IRSA) to make AWS API calls:

```bash
$ kubectl get serviceaccounts -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o yaml
```

Example output:

::yaml{file="manifests/modules/troubleshooting/alb/files/iam_issue_service_account_role.yaml" paths="items.0.metadata.annotations"}

1. `eks.amazonaws.com/role-arn`: This tag references IAM role that needs the correct permissions.

### Step 2: Check Controller Logs

Let's examine the Load Balancer Controller logs to understand the permission issues:

```bash wait=25  expectError=true
$ kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

You might see an error like this:

```text
{"level":"error","ts":"2024-06-11T14:24:24Z","msg":"Reconciler error","controller":"ingress","object":{"name":"ui","namespace":"ui"},"namespace":"ui","name":"ui","reconcileID":"49d27bbb-96e5-43b4-b115-b7a07e757148","error":"AccessDenied: User: arn:aws:sts::xxxxxxxxxxxx:assumed-role/alb-controller-20240611131524228000000002/1718115201989397805 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer on resource: arn:aws:elasticloadbalancing:us-west-2:xxxxxxxxxxxx:loadbalancer/app/k8s-ui-ui-5ddc3ba496/* because no identity-based policy allows the elasticloadbalancing:CreateLoadBalancer action\n\tstatus code: 403, request id: a24a1620-3a75-46b7-b3c3-9c80fada159e"}
```

The error indicates the IAM role lacks the `elasticloadbalancing:CreateLoadBalancer` permission.

### Step 3: Fix the IAM Policy

To resolve this, we need to update the IAM role with the correct permissions. For this workshop, we've pre-created the correct policy with the necessary IAM policy permissions based on the [installation guide](https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html) for the AWS Load Balancer Controller:

Now we'll:

#### 3.1. Attach the correct policy

```bash
$ aws iam attach-role-policy \
    --role-name ${LOAD_BALANCER_CONTROLLER_ROLE_NAME} \
    --policy-arn ${LOAD_BALANCER_CONTROLLER_POLICY_ARN_FIX}
```

#### 3.2. Remove the incorrect policy

```bash
$ aws iam detach-role-policy \
    --role-name ${LOAD_BALANCER_CONTROLLER_ROLE_NAME} \
    --policy-arn ${LOAD_BALANCER_CONTROLLER_POLICY_ARN_ISSUE}
```

#### 3.3. Restart the Load Balancer Controller to pick up the new subnet configuration

```bash
$ kubectl -n kube-system rollout restart deploy aws-load-balancer-controller
deployment.apps/aws-load-balancer-controller restarted
$ kubectl -n kube-system wait --for=condition=available deployment/aws-load-balancer-controller
```

### Step 4: Verify the Fix

Check if the ingress is now properly configured with an ALB:

```bash timeout=600 hook=fix-5 hookTimeout=600
$ kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-ui-5ddc3ba496-1208241872.us-west-2.elb.amazonaws.com
```

:::tip
**The Load Balancer creation can take a few minutes**. You can verify the process by:

1. Checking CloudTrail for successful `CreateLoadBalancer` API calls
2. Monitoring the controller logs for successful creation messages
3. Watching the ingress resource for the ALB DNS name to appear

:::

For reference, the complete set of permissions required for the AWS Load Balancer Controller can be found in the [official documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/#setup-iam-manually).
