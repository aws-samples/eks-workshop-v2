---
title: "Restricting Image Registries"
sidebar_position: 73
---

Using container images from unknown sources in your EKS clusters can pose significant security risks, especially if these images haven't been scanned for Common Vulnerabilities and Exposures (CVEs). To mitigate these risks and reduce the threat of vulnerability exploitation, it's crucial to ensure that container images originate from trusted registries. Many organizations also have security guidelines that mandate the use of images exclusively from their own hosted private image registries.

In this section, we'll explore how Kyverno can help you run secure container workloads by restricting the image registries that can be used in your cluster.

As demonstrated in previous labs, you can deploy workloads with images from any available registry. Let's start by creating a sample Deployment using the default registry, which points to `docker.io`:

```bash hook=registry-setup
$ kubectl create deployment nginx-public --image=nginx
deployment.apps/nginx-public created

$ kubectl get deployment nginx-public -o jsonpath='{.spec.template.spec.containers[0].image}'
nginx
```

In this case, we've referenced a basic `nginx` image from the public registry. However, a malicious actor could potentially deploy a vulnerable image and run it on the EKS cluster, potentially exploiting the cluster's resources.

To implement best practices, we'll define a policy that restricts the use of unauthorized image registries and relies only on specified trusted registries.

For this lab, we'll use the [Amazon ECR Public Gallery](https://public.ecr.aws/) as our trusted registry, blocking any Deployments that reference images hosted in other registries. Here's a sample Kyverno policy to restrict image pulling for this use case:

::yaml{file="manifests/modules/security/kyverno/images/restrict-registries.yaml" paths="spec.validationFailureAction,spec.background,spec.rules.0.match,spec.rules.0.validate.allowExistingViolations,spec.rules.0.validate.pattern"}

1. `validationFailureAction: Enforce` blocks non-compliant Deployments from being created or updated
2. `background: true` applies the policy to existing resources in addition to new ones
3. `match.any.resources.kinds: [Deployment]` applies the policy to all Deployment resources cluster-wide
4. `allowExistingViolations: false` ensures updates to already-violating Deployments are also blocked, closing the gap where a pre-existing non-compliant Deployment could otherwise be updated without enforcement
5. `validate.pattern` enforces that all container images in the Deployment pod template must originate from the `public.ecr.aws/*` registry, blocking any Deployments that reference images from unauthorized registries

> Note: This policy targets Deployments. InitContainers and Ephemeral Containers are not covered by this pattern.

Let's apply this policy using the following command:

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/images/restrict-registries.yaml

clusterpolicy.kyverno.io/restrict-image-registries created
```

Now, let's attempt to create a new Deployment using an image from the public registry:

```bash expectError=true hook=registry-blocked
$ kubectl create deployment nginx-blocked --image=nginx
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/default/nginx-blocked was blocked due to the following policies

restrict-image-registries:
  validate-registries: 'validation error: Unknown Image registry. rule validate-registries
    failed at path /spec/template/spec/containers/0/image/'
```

As we can see, the Deployment was blocked due to our previously created Kyverno policy.

Let's now try to create a Deployment using the `nginx` image hosted in our trusted registry (public.ecr.aws), which we defined in the policy:

```bash
$ kubectl create deployment nginx-ecr --image=public.ecr.aws/nginx/nginx
deployment.apps/nginx-ecr created
```

Success! The Deployment was created successfully because its pod template references an image from the trusted registry.

We've now seen how we can block Deployments that reference images from public registries and restrict usage to only allowed image repositories. As a further security best practice, you might consider allowing only private repositories.

> Note: Don't remove the running Deployments created in this task, as we'll use them in the next lab.
