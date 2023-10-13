---
title : "Restricting Image Registries"
weight : 135
---

Images used to run Containers on EKS Clusters from unkwown sources may not be a scanned and trusted, representing a risk factor. Using Container Images from Trusted Registries helps reducing the threat exposure of vulnerability. 
Organizations also have Security Guidelines to use only trusted Images & often restrict the use of Images limited to their own hosted Private Image Repositories. 

In this section, we will see how Kyverno can help us run secure Container Workloads, by restricting the Image Registries that can be use to run our Applications.

First we will try to run an Sample Nginx Pod using the below:

:::code{showCopyAction=true showLineNumbers=true}
kubectl run nginx-badpod --image=nginx:latest
:::

We can see the sample output, that our pod is running successfully. 
:::code{}
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          47s
:::

In this case, it was just an Nginx Image being pulled from the Public Registry. A Bad actor, could pull any vulnerable image, and run on the EKS cluster exploiting resources allocated to the cluster.

Now, we will see on how we can use of any Unauthorized Public Registry Images to be used in the organization as a best Practice.

In our example, we will be using [Amazon ECR Public Gallery](https://gallery.ecr.aws/) to restrict our Container Applications to aws-containers Public repository. Below is the sample Kyverno Policy to restrict the Image Pull for our use-case

:::code{showCopyAction=true showLineNumbers=true}
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-image-registries
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: validate-registries
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Unknown Image registry."
      pattern:
        spec:
          containers:
          - image: "public.ecr.aws/aws-containers/*"
:::

> Note: The above doesn't restrict usage of InitContainers or Ephemeral Containers to the `aws-containers` repository. The above policy is suggested to customize according to the requirements to limit usage to approved registries.

We will apply the above policy using the `Kubectl apply -f <file_name>.yaml` command & run an Application on our EKS Cluster.

::::expand{header="Output"}
```yaml
clusterpolicy.kyverno.io/restrict-image-registries created
```
::::

Now, we will try to create another Sample Nginx Application

:::code{showCopyAction=true showLineNumbers=true}
kubectl run nginx-badpod02 --image=nginx:latest
:::

It will fail to run successfully, and will give us the below output stating Pod Creation was blocked due to our previously created Kyverno Policy:

:::code{}
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Pod/default/nginx-badpod02 was blocked due to the following policies 

restrict-image-registries:
  validate-registries: 'validation error: Unknown Image registry. rule validate-registries
    failed at path /spec/containers/0/image/'

:::

We have successfully seen, how we can block Images from public registries to run on our EKS clusters, and restrict only allowed Image Repositories. One can further go ahead, and allow only private ECR repositories as a Security Best Practice.