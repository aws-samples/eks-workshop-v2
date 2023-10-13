---
title: "Introduction on Kyverno"
sidebar_position: 131
---

Kyverno (Greek for “govern”) is a policy engine designed specifically for Kubernetes. Kyverno a Cloud Native Computing Foundation (CNCF) incubating project, is a Policy-as-Code (PaC) solution that includes a policy engine designed for Kubernetes. 

The Kyverno policy engine is installed into Kubernetes clusters and integrated to the Kubernetes API server as [Dynamic Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/). This allows Kyverno policies to be used to mutate and validate inbound Kubernetes API server requests before the requests persist changes into the internal Kubernetes etcd data store.

Kyverno policies are declarative Kubernetes resources, **written in YAML, with no new policy language to learn.** Policy results are also available as Kubernetes resources and as events. 

Kyverno policies can be used to **validate, mutate, and generate resource configurations, and validate image signatures and attestations.**

### How Kyverno Works
---
As mentioned above, Kyverno runs as a Dynamic Admission Controller in an Kubernetes Cluster. Kyverno receives validating and mutating admission webhook HTTP callbacks from the Kubernetes API server and applies matching policies to return results that enforce admission policies or reject requests. It can also be used to Audit the requests, to monitor the Security posture of the environment before enforcing.

Kyverno policies can be created for resources using Resource Kind, Labels, Namespaces, Roles, ClusterRoles and many more.

The diagram below shows the high-level logical architecture of Kyverno.

![KyvernoArchitecture](assets/ky-arch.png)

The two major components are the Webhook Server & the Webhook Controller. The **Webhook server** handles incoming AdmissionReview requests from the Kubernetes API server and sends them to the Engine for processing. It is dynamically configured by the **Webhook Controller** which watches the installed policies and modifies the webhooks to request only the resources matched by those policies.

Next we will take a look at the Workshop Activities. Click Next to Start with the Lab