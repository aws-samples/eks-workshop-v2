---
title: "Restricting Image Registries"
sidebar_position: 73
---

Using container images from unknown sources in your EKS clusters can pose significant security risks, especially if these images haven't been scanned for Common Vulnerabilities and Exposures (CVEs). To mitigate these risks and reduce the threat of vulnerability exploitation, it's crucial to ensure that container images originate from trusted registries. Many organizations also have security guidelines that mandate the use of images exclusively from their own hosted private image registries.

In this section, we'll explore how Kyverno can help you run secure container workloads by restricting the image registries that can be used in your cluster.

As demonstrated in previous labs, you can run Pods with images from any available registry. Let's start by running a sample Pod using the default registry, which points to `docker.io`:

```bash
$ kubectl run nginx --image=nginx

NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          47s

$ kubectl describe pod nginx | grep Image
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:4c0fdaa8b6341bfdeca5f18f7837462c80cff90527ee35ef185571e1c327beac
```

In this case, we've pulled a basic `nginx` image from the public registry. However, a malicious actor could potentially pull a vulnerable image and run it on the EKS cluster, potentially exploiting the cluster's resources.

To implement best practices, we'll define a policy that restricts the use of unauthorized image registries and relies only on specified trusted registries.

For this lab, we'll use the [Amazon ECR Public Gallery](https://public.ecr.aws/) as our trusted registry, blocking any containers that use images hosted in other registries. Here's a sample Kyverno policy to restrict image pulling for this use case:

::yaml{file="manifests/modules/security/kyverno/images/restrict-registries.yaml" paths="spec.validationFailureAction,spec.background,spec.rules.0.match,spec.rules.0.validate.pattern"}

1. `validationFailureAction: Enforce` blocks non-compliant Pods from being created
2. `background: true` applies the policy to existing resources in addition to new ones
3. `match.any.resources.kinds: [Pod]` applies the policy to all Pod resources cluster-wide
4. `validate.pattern` enforces that all container images must originate from the `public.ecr.aws/*` registry, blocking any images from unauthorized registries

> Note: This policy doesn't restrict the usage of InitContainers or Ephemeral Containers to the referred repository.

Let's apply this policy using the following command:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/images/restrict-registries.yaml

clusterpolicy.kyverno.io/restrict-image-registries created
```

Now, let's attempt to run another sample Pod using the default image from the public registry:

```bash expectError=true
$ kubectl run nginx-public --image=nginx

Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/default/nginx-public was blocked due to the following policies

restrict-image-registries:
  validate-registries: 'validation error: Unknown Image registry. rule validate-registries
    failed at path /spec/containers/0/image/'
```

As we can see, the Pod failed to run, and we received an output stating that Pod creation was blocked due to our previously created Kyverno policy.

Let's now try to run a sample Pod using the `nginx` image hosted in our trusted registry (public.ecr.aws), which we defined in the policy:

```bash
$ kubectl run nginx-ecr --image=public.ecr.aws/nginx/nginx
pod/nginx-public created
```

Success! The Pod was created successfully.

We've now seen how we can block images from public registries from running on our EKS clusters and restrict usage to only allowed image repositories. As a further security best practice, you might consider allowing only private repositories.

> Note: Don't remove the running Pods created in this task, as we'll use them in the next lab.
