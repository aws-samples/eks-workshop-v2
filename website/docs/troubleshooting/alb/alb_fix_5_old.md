---
title: "Fixing Policy Issue OLD"
sidebar_position: 31
---

In this section we will cover a specific troubleshooting step to address issues where the ALB is not properly forwarding traffic to the target groups. It provides step-by-step instructions and relevant configuration examples to help resolve this problem.

### Step 5

With this setup, we’re leveraging IAM Roles for Service Accounts, which essentially allows pods to assume IAM roles using service accounts in Kubernetes and OIDC provider associated with your EKS cluster. Locate the service account that load balancer controller is using and find out the IAM role associated with it, to identify the IAM entity that would make API calls to provision your load balancer.
Try running:

```bash
$ kubectl get serviceaccounts -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o yaml
```

```yaml {8}
apiVersion: v1
items:
  - apiVersion: v1
    automountServiceAccountToken: true
    kind: ServiceAccount
    metadata:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/alb-controller-20240611131524228000000002
        meta.helm.sh/release-name: aws-load-balancer-controller
        meta.helm.sh/release-namespace: kube-system
      creationTimestamp: "2024-06-11T13:15:32Z"
      labels:
        app.kubernetes.io/instance: aws-load-balancer-controller
        app.kubernetes.io/managed-by: Helm
        app.kubernetes.io/name: aws-load-balancer-controller
        app.kubernetes.io/version: v2.7.1
        helm.sh/chart: aws-load-balancer-controller-1.7.1
      name: aws-load-balancer-controller-sa
      namespace: kube-system
      resourceVersion: "4950707"
      uid: 6d842045-f2b4-4406-869b-f2addc67ff4d
kind: List
metadata:
  resourceVersion: ""
```

:::tip
Can you verify if there’s a call in your CloudTrail events with the IAM role listed in the output for above command? If not, take a look at the logs from your controller.
:::

### Step 6

You can check the logs from controller pods to find additional details which could be preventing the load balancer to create. Let's check the logs using the command below.

```bash
$ kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

For example the output may show something similar to the below output.

```text
{"level":"error","ts":"2024-06-11T14:24:24Z","msg":"Reconciler error","controller":"ingress","object":{"name":"ui","namespace":"ui"},"namespace":"ui","name":"ui","reconcileID":"49d27bbb-96e5-43b4-b115-b7a07e757148","error":"AccessDenied: User: arn:aws:sts::xxxxxxxxxxxx:assumed-role/alb-controller-20240611131524228000000002/1718115201989397805 is not authorized to perform: elasticloadbalancing:CreateLoadBalancer on resource: arn:aws:elasticloadbalancing:us-west-2:xxxxxxxxxxxx:loadbalancer/app/k8s-ui-ui-5ddc3ba496/* because no identity-based policy allows the elasticloadbalancing:CreateLoadBalancer action\n\tstatus code: 403, request id: a24a1620-3a75-46b7-b3c3-9c80fada159e"}
```

As you can see the error indicates the IAM role does not have the correct permissions, in this case the permissions to create the load balancer `elasticloadbalancing:CreateLoadBalancer`.

:::tip
Verify the correct permissions required by the IAM role in the documentations here [[1]](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/#setup-iam-manually) where you can find the latest IAM permissions json file required for the LB Controller. After the changes, you have to wait a few minutes for the changes to reflect, since IAM uses an eventual consistency model. To make the changes, locate the IAM role through the AWS console and add the missing permissions that are shown in the log. In this case CreateLoadBalancer is missing.
:::

Now let's fix it. To avoid conflicts with the automation of the workshop, we have already provisioned the correct permissions into the account and added the environment variable `LOAD_BALANCER_CONTROLLER_ROLE_NAME` that contains the role name and `LOAD_BALANCER_CONTROLLER_POLICY_ARN_FIX` which contains the correct IAM policy arn, and `LOAD_BALANCER_CONTROLLER_POLICY_ARN_ISSUE` that contains the incorrect IAM policy arn.

So, to fix it we will just need to attach the correct IAM policy, as follows:

```bash
$ aws iam attach-role-policy --role-name ${LOAD_BALANCER_CONTROLLER_ROLE_NAME} --policy-arn ${LOAD_BALANCER_CONTROLLER_POLICY_ARN_FIX}
```

and detach the incorrect IAM policy from the role:

```bash
$ aws iam detach-role-policy --role-name ${LOAD_BALANCER_CONTROLLER_ROLE_NAME} --policy-arn ${LOAD_BALANCER_CONTROLLER_POLICY_ARN_ISSUE}
```

Try accessing the new Ingress URL in the browser as before to check if you can access the UI app:

```bash timeout=180 hook=fix-5 hookTimeout=600
$ kubectl get ingress -n ui ui -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}"
k8s-ui-ui-5ddc3ba496-1208241872.us-west-2.elb.amazonaws.com
```

:::tip
It can take a couple of minutes for the Load Balancer to be available once created.
:::

Also, feel free to go to CloudTrail again and verify the API call for CreateLoadBalancer is there.
