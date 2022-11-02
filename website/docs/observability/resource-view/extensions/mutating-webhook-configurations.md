---
title: "MutatingWebhookConfigurations"
sidebar_position: 48
---

[Mutating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook) modify objects sent to the API server to enforce custom defaults. Their configuration includes the custom defaults.

![Insights](/img/resource-view/ext-mutatingwebhook.jpg)

Below screen shows the details of _aws-load-balancer-webhook_ , way webhook works is the admission controller calls any mutating webhooks which match the request. Matching webhooks are called in serial; each one may modify the object if it desires

![Insights](/img/resource-view/ext-mutatingwebhook-detail.jpg)
