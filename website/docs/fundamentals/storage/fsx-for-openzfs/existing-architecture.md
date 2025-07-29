---
title: Existing architecture
sidebar_position: 10
---

In this section, we'll explore how to handle storage in Kubernetes deployments using a simple image hosting example. We'll start with an existing deployment from our sample store application and modify it to serve as an image host. The UI component is a stateless microservice, which is an excellent example for demonstrating deployments since they enable **horizontal scaling** and **declarative state management** of Pods.

One of the roles of the UI component is to serve static product images. Currently, these images are bundled into the container during the build process. However, this approach has a significant limitation - we're unable to add new images once the container is deployed. To address this limitation, we'll implement a solution using [Amazon FSx for OpenZFS](https://docs.aws.amazon.com/fsx/latest/OpenZFSGuide/what-is-fsx.html) and Kubernetes [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) to create a shared storage environment. This will allow multiple web server containers to serve assets while scaling dynamically to meet demand.

Let's examine the current Deployment's volume configuration:

```bash
$ kubectl describe deployment -n ui
Name:                   ui
Namespace:              ui
[...]
  Containers:
   ui:
    Image:      public.ecr.aws/aws-containers/retail-store-sample-ui:1.2.1
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      memory:  1536Mi
    Requests:
      cpu:     250
      memory:  1536Mi
    [...]
    Mounts:
      /tmp from tmp-volume (rw)
  Volumes:
   tmp-volume:
    Type:          EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:        Memory
    SizeLimit:     <unset>
[...]
```

Looking at the [`Volumes`](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir-configuration-example) section, we can see that the Deployment currently uses an [EmptyDir volume type](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) that exists only for the Pod's lifetime. This means that when the Pod is terminated, the data stored in this volume is permanently lost.

However, in the case of the UI component, the product images are currently being served as [static web content](https://spring.io/blog/2013/12/19/serving-static-web-content-with-spring-boot) via Spring Boot, so the images are not even present on the filesystem.
