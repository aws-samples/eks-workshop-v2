---
title: "WebhookConfigurations"
sidebar_position: 48
---
Webhook configurations are executed during the process of intercepting authenticated API request to accept an object request or deny an object by _[Kubernetes Admission controllers](https://kubernetes.io/blog/2019/03/21/a-guide-to-kubernetes-admission-controllers/)_. Kuberneted admission controllers sets a security baseline across namespace or cluster. Following picture decribes the different steps involved in admission controller process.

![Insights](/img/resource-view/ext-admincontroller.png)

[Mutating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook) modify objects sent to the API server to enforce custom defaults. 

![Insights](/img/resource-view/ext-mutatingwebhook.jpg)

Below screen shows the details of _aws-load-balancer-webhook_ , in this example `Match policy = Equivalent` which means 
request will be sent to webhook by modifying the object as per the webhook version `Admission review version = v1beta1`. If `Match policy = Equal` and if the request has a different webhook version then the request will not be sent to webhook. By calling the webhook will have no side effects as it is set to `None`. If the webhook did not respond as per `Timeout seconds = 10`, then request will be rejected.

![Insights](/img/resource-view/ext-mutatingwebhook-detail.jpg)

**[Validating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#validatingadmissionwebhook)** validate requests to the API server. Their configuration includes settings to validate requests. Configurations of _ValidatingAdmissionWebhooks_ is similar to _MutatingAdmissionWebhook_, but the difference it makes the final status of request object is stored in etcd by validation webhook.

![Insights](/img/resource-view/ext-valiatewebhook-detail.jpg)