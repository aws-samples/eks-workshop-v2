---
title: "Deploy the Controller"
sidebar_position: 5
---

Follow these instructions to deploy the AWS Load Balancer Controller with Gateway API support.

The `prepare-environment` step has already installed the Gateway API CRDs and created the necessary IAM roles. Now we'll install the AWS Load Balancer Controller using Helm.

Install the AWS Load Balancer Controller with Gateway API support enabled:

```bash wait=30
$ helm repo add eks-charts https://aws.github.io/eks-charts
$ helm upgrade --install aws-load-balancer-controller eks-charts/aws-load-balancer-controller \
  --version "${LBC_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "clusterName=${EKS_CLUSTER_NAME}" \
  --set "serviceAccount.name=aws-load-balancer-controller-sa" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$LBC_ROLE_ARN" \
  --set "defaultTargetType=ip" \
  --wait
Release "aws-load-balancer-controller" does not exist. Installing it now.
NAME: aws-load-balancer-controller
LAST DEPLOYED: [...]
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!
```

The controller will now be running as a deployment:

```bash
$ kubectl get deployment -n kube-system aws-load-balancer-controller
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           30s
```

Confirm that the Gateway API CRDs are available in the cluster:

```bash
$ kubectl get crds | grep gateway
gatewayclasses.gateway.networking.k8s.io              [...]
gateways.gateway.networking.k8s.io                    [...]
httproutes.gateway.networking.k8s.io                  [...]
referencegrants.gateway.networking.k8s.io             [...]
```

Currently there are no Gateway resources in our cluster:

```bash expectError=true
$ kubectl get gateway -A
No resources found
```

There are also no HTTPRoute resources:

```bash expectError=true
$ kubectl get httproute -A
No resources found
```

With the controller deployed, we're ready to create Gateway API resources to expose our application through an Application Load Balancer.
