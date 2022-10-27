---
title: "ValidatingWebhookConfigurations"
sidebar_position: 49
---

**[Validating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#validatingadmissionwebhook)** validate requests to the API server. Their configuration includes settings to validate requests.

![Insights](/img/resource-view/ext-valiatewebhook.jpg)

This admission controller calls any validating webhooks which match the request. Matching webhooks are called in parallel; if any of them rejects the request, the request fails. This admission controller only runs in the validation phase; the webhooks it calls may not mutate the object, as opposed to the webhooks called by the _MutatingAdmissionWebhook_ admission controller

![Insights](/img/resource-view/ext-valiatewebhook-detail.jpg)