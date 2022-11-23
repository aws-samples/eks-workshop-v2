---
title: "Webhook Configurations"
sidebar_position: 48
---
Webhook configurations are executed during the process of intercepting authenticated API request to accept an object request or deny an object by _[Kubernetes Admission controllers](https://kubernetes.io/blog/2019/03/21/a-guide-to-kubernetes-admission-controllers/)_. Kubernetes admission controllers sets a security baseline across namespace or cluster. The following diagram decribes the different steps involved in the admission controller process.

![Insights](/img/resource-view/ext-admincontroller.png)

[Mutating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook) modify objects sent to the API server to enforce custom defaults. 

Under **_Resource Types_** - **_Extensions_** you can view a list of the **_Mutating Webhook Configurations_** on the cluster

![Insights](/img/resource-view/ext-mutatingwebhook.jpg)

The below screenshot shows the details of the _aws-load-balancer-webhook_. You can see in this webhook configuration that `Match policy = Equivalent` which means 
request will be sent to webhook by modifying the object as per the webhook version `Admission review version = v1beta1`. 

When the configuration `Match policy = Equivalent` then when a new request is processed but has a different webhook version  then specified in the configuration, the request will not be sent to webhook. Notice the _Side Effects_ is set to `None` and the _Timeout Seconds_ is set to `10` meaning this webhook has no side effects and will be rejected after 10 seconds. 

![Insights](/img/resource-view/ext-mutatingwebhook-detail.jpg)

**[Validating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#validatingadmissionwebhook)** validate requests to the API server. Their configuration includes settings to validate requests. Configurations of **_ValidatingAdmissionWebhooks_** are similar to **_MutatingAdmissionWebhook_**, however the final status of **_ValidatingAdmissionWebhooks_** request objects are stored in etcd.

![Insights](/img/resource-view/ext-valiatewebhook-detail.jpg)
