---
title: "External DNS"
sidebar_position: 30
---

[ExternalDNS](https://github.com/kubernetes-sigs/external-dns) is a Kubernetes controller that automatically manages DNS records for your cluster's services and ingresses. It acts as a bridge between Kubernetes resources and DNS providers like AWS Route 53, ensuring your DNS records stay synchronized with your cluster's state. Using DNS entries for your load balancers provides human-readable, memorable addresses instead of auto-generated host names, making your services easily accessible and recognizable as your corporate resources with domain names that align with your organization's branding

In this lab we'll automate DNS management for Kubernetes Ingress resources using ExternalDNS with AWS Route 53.

First let's install ExternalDNS using Helm, with the IAM role ARN and Helm chart version provided as environment variables:

```bash
$ helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
$ helm upgrade --install external-dns external-dns/external-dns --version "${DNS_CHART_VERSION}" \
    --namespace external-dns \
    --create-namespace \
    --set provider.name=aws \
    --set serviceAccount.create=true \
    --set serviceAccount.name=external-dns-sa \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$DNS_ROLE_ARN" \
    --set txtOwnerId=eks-workshop \
    --set extraArgs[0]=--aws-zone-type=private \
    --set extraArgs[1]=--domain-filter=retailstore.com \
    --wait
```

Check that the ExternalDNS pod is running:

```bash
$ kubectl -n external-dns get pods
NAME                                READY   STATUS    RESTARTS   AGE
external-dns-5bdb4478b-fl48s        1/1     Running   0          2m
```

Now let's update our previous Ingress resource with DNS configuration:

::yaml{file="manifests/modules/exposing/ingress/external-dns/ingress.yaml" paths="metadata.annotations,spec.rules.0.host"}

1. The annotation `external-dns.alpha.kubernetes.io/hostname` tells ExternalDNS which DNS name to create and manage for the Ingress, automating the mapping of your app’s hostname to its load balancer.
2. The `spec.rules.host` defines the domain name your Ingress will listen to, which ExternalDNS uses to create a matching DNS record for the associated load balancer.

Apply this configuration:

```bash
$ kubectl apply -k ~/environment/eks-workshop/modules/exposing/ingress/external-dns
```

Let's inspect the Ingress object created with host name:

```bash wait=120
$ kubectl get ingress ui   -n ui
NAME     CLASS   HOSTS                    ADDRESS                                            PORTS   AGE
ui       alb     ui.retailstore.com       k8s-ui-ui-1268651632.us-west-2.elb.amazonaws.com   80      4m15s
```

Verifying DNS record creation, ExternalDNS will automatically create the DNS record in the `retailstore.com` Route 53 private hosted zone.

:::note

It can take several minutes for the DNS entries to be reconciled.

:::

Check ExternalDNS logs to confirm DNS record creation:

```bash hook=dns-logs
$ kubectl -n external-dns logs deployment/external-dns
Desired change: CREATE ui.retailstore.com A
5 record(s) were successfully updated
```

You can also verify the new DNS record in the AWS Route 53 console by clicking the link and navigating to the `retailstore.com` private hosted zone:

<ConsoleButton url="https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones" service="route53" label="Open Route53 console"/>

Route 53 private hosted zones are only accessible from associated VPCs, in this case the EKS cluster VPC. To test the DNS entry we'll use `curl` from inside a pod:

```bash hook=dns-curl
$ kubectl -n ui exec -it \
  deployment/ui -- curl -i http://ui.retailstore.com/actuator/health/liveness

HTTP/1.1 200 OK
Date: Thu, 24 Apr 2025 07:45:12 GMT
Content-Type: application/vnd.spring-boot.actuator.v3+json
Content-Length: 15
Connection: keep-alive
Set-Cookie: SESSIONID=c3f13e02-4ff3-40ba-866e-c777f7450997

{"status":"UP"}
```
