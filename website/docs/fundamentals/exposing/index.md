---
title: "Exposing applications"
sidebar_position: 30
---

Right now our web store application is not exposed to the outside world, theres no way for users to access it. Although there are many microservices in our web store workload, to provide access to end-users only a single service needs to be available and that is the `ui` application. This is because the `ui` application will perform all communication to the other backend services using internal Kubernetes networking.

In this chapter of the workshop we'll take a look at the various mechanisms available when using EKS to expose an application to end users.
