---
title: "Restricting Image Registries"
sidebar_position: 73
---

Using container images form unknown sources on your EKS Clusters, that may not be a scanned for Common Vulnerabilities and Exposure (CVE), represent a risk factor for the overall security of your environment. When chossing container images sources, you need to ensure that they are originated from Trusted Registries, in order to reduce the threat exposure and exploits of vulnerabilities. Some larger organizations also have Security Guidelines that limit containers to use images from their own hosted private image registry.

In this section, you will see how Kyverno can help you run secure container workloads by restricting the Image Registries that can be used in your cluster.

As seen in previous labs, you can run Pods with images from any available registry, so run a sample Pod using the default registry that points to `docker.io`.

```bash
$ kubectl run nginx --image=nginx

NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          47s

$ kubectl describe pod nginx | grep Image
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:4c0fdaa8b6341bfdeca5f18f7837462c80cff90527ee35ef185571e1c327beac
```

In this case, it was just an `nginx` base image being pulled from the Public Registry. A bad actor could pull any vulnerable image and run on the EKS Cluster, exploiting resources allocated in the cluster.

Next, as a best practice you'll define a policy that will restrict the use of any unauthorized Image Registry, and rely only on specified Trusted Registries.

In this lab, you will be using [Amazon ECR Public Gallery](https://public.ecr.aws/) as the Trusted Registry, blocking any containers that use Images hosted in other tegistries to run. Below is a sample Kyverno Policy to restrict the image pull for this use-case.

```file
manifests/modules/security/kyverno/images/restrict-registries.yaml
```

> The above doesn't restrict usage of InitContainers or Ephemeral Containers to the referred repository.

Apply the above policy with the command below.

```bash
$ kubectl apply -f ~/environment/eks-workshop/modules/security/kyverno/images/restrict-registries.yaml

clusterpolicy.kyverno.io/restrict-image-registries created
```

Try to run another sample Pod using the default image from the public Registry.

```bash expectError=true
$ kubectl run nginx-public --image=nginx

Error from server: admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Pod/default/nginx-public was blocked due to the following policies 

restrict-image-registries:
  validate-registries: 'validation error: Unknown Image registry. rule validate-registries
    failed at path /spec/containers/0/image/'
```

The Pod failed to run and presented an output stating Pod Creation was blocked due to our previously created Kyverno Policy.

Now try to run a sample Pod using the `nginx` Image hosted in the Trusted Registry, previously defined in the Policy (public.ecr.aws).

```bash
$ kubectl run nginx-ecr --image=public.ecr.aws/nginx/nginx
pod/nginx-public created
```

The Pod was successfuly created!

You have seen how you can block Images from public registries to run on your EKS Clusters, and restrict only allowed Image Repositories. One can further go ahead, and allow only private repositories as a Security Best Practice.

> Don't remove the running Pods created in this task as we will use them for the next lab.
