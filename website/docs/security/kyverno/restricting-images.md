---
title: "Restricting Image Registries"
sidebar_position: 135
---

Images used to run Containers on EKS Clusters from unknown sources may not be a scanned and trusted, representing a risk factor. Using Container Images from Trusted Registries helps reducing the threat exposure of vulnerability. Organizations also have Security Guidelines to use only trusted Images & often restrict the use of Images limited to their own hosted Private Image Repositories.

In this section, you will see how Kyverno can help us run secure container workloads, by restricting the Image Registries that can be use to run your applications.

As seen in previous labs, you can run Pods with images from any available registry, so run a sample Pod using the default registry that pois to `docker.io`.

```bash
$ kubectl run nginx --image=nginx:latest

NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          47s

$ kubectl describe pod nginx | grep Image
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:4c0fdaa8b6341bfdeca5f18f7837462c80cff90527ee35ef185571e1c327beac
```

In this case, it was just an `nginx` image being pulled from the Public Registry. A bad actor could pull any vulnerable image and run on the EKS Cluster, exploiting resources allocated to the cluster.

Now, as a best practice you'll define a policy that will restrict the use of any unauthorized Image Registry, and rely only on Trusted Registries.

In the example, you will be using [Amazon ECR Public Gallery](https://gallery.ecr.aws/) as the Trusted Registry, restricting any containers to use Images hosted in other Registries. Below is the sample Kyverno Policy to restrict the image pull for this use-case.

```file
manifests/modules/security/kyverno/images/restrict-registries.yaml
```

> Note: The above doesn't restrict usage of InitContainers or Ephemeral Containers to the `aws-containers` repository. The above policy is suggested to customize according to the requirements to limit usage to approved registries.

Apply the above policy with the command below.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/main/manifests/modules/security/kyverno/images/restrict-registries.yaml

clusterpolicy.kyverno.io/restrict-image-registries created
```

Try to run another sample Pod using the default image from the public Registry.

```bash
$ kubectl run nginx-public --image=nginx:latest

Error from server: admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Pod/default/nginx-public was blocked due to the following policies 

restrict-image-registries:
  validate-registries: 'validation error: Unknown Image registry. rule validate-registries
    failed at path /spec/containers/0/image/'
```

The Pod failed to run, and showed in the output stating Pod Creation was blocked due to our previously created Kyverno Policy.

Now try to run a sample Pod using the Image hosted in the Trusted Registry, previously defined in the Policy (public.ecr.aws)

```bash
$ kubectl run nginx-ecr --image=public.ecr.aws/nginx/nginx:latest
pod/nginx-public created
```

The Pod was successfuly created!

You have seen how you can block Images from public registries to run on your EKS Clusters, and restrict only allowed Image Repositories. One can further go ahead, and allow only private repositories as a Security Best Practice.

Run the following command to cleanup the Pod resources created on this lab.

```bash
$ kubectl delete pod nginx nginx-ecr
pod "nginx" deleted
pod "nginx-ecr" deleted
```
