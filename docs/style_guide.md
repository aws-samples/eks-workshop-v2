# EKS Workshop - Style Guide

This document provides a style guide that should be used when creating or modifying content for the workshop in order to maintain a consistent experience throughout the content.

## General content

### Web IDE

The users of the content will be interacting with it through a web IDE, such as VSCode. Any references to this IDE should ALWAYS use "web IDE" or "IDE" and never specific terminology such as VSCode, Cloud9 or code-server.

### Use admonitions

Use appropriate [Docusaurus admonitions](https://docusaurus.io/docs/markdown-features/admonitions) to call out relevant information.

```markdown
:::info

Use info blocks for additional information

:::

:::caution

Caution blocks also available

:::

:::note

Note blocks are available

:::
```

### Badges

To mark your module as an independent module that users can begin with, place the following in the header of your markdown file:

```markdown
---

...
sidebar_custom_props: { "module": true }
---
```

To mark your module as informational, with no actionable steps, place the following in the header of your markdown file:

```markdown
---

...
sidebar_custom_props: { "info": true }
---
```

To mark your module as external content, which at the moment is only used for other AWS workshops, place the following in the header of your markdown file:

```markdown
---

...
sidebar_custom_props: { "explore": "https://<external link here>" }
---
```

To mark your module as optional:
```
---
...
sidebar_custom_props:  { "optional": "true" }
---
```

### Navigating the AWS console

There are instances where the user needs to navigate to specific screens in the AWS console. It is preferable to provide a link to the exact screen if possible, or a close as can be done.

For example to link to the EKS console you can use a link like this:

```text
https://console.aws.amazon.com/eks/home#/clusters
```

> Note that this has had the region information removed, the link as shown in the browser would be: `https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters`. The region must be removed to allow the content to be portable.

These links should be displayed to the user with the [Console button component](./ui_components.md) for consistency.

### Screenshots

Use of screenshots should be limited to only wherever necessary. Where possible command-line output should be used as it is more maintainable and testable. When screenshots are necessary only the relevant section of the screen should be included as it reduces image size and makes the images more legible, especially for users with limited screen resolution. Screenshots should be cropped to display only the necessary details.

## Technical Terminology

Any references to command line tools should always use inline code fence to reference the name when used in paragraphs or sentences. For example `aws`, `kubectl` or `eksctl`. If the technology is being referred to more abstracted then use that name is it usually appears.

For example:

Abstract: "We'll be using Terraform to manage our infrastructure automation"

Command-line: "Lets run the `terraform` tool to create our infrastructure"

### Containers Terminology

Containers images should be referred to using this term. Any references to "Docker image" should instead use "container image".

### Kubernetes Terminology

Kubernetes uses the word resource to refer to API resources. For example, the URL path `/apis/apps/v1/namespaces/default/deployments/my-app` represents a Deployment named "my-app" in the "default" namespace. In HTTP jargon, namespace is a resource - the same way that all web URLs identify a resource.

Kubernetes documentation also uses "resource" to talk about CPU and memory requests and limits. It's very often a good idea to refer to API resources as "API resources"; that helps to avoid confusion with CPU and memory resources, or with other kinds of resource.

The different Kubernetes API terminologies are:

- API kinds: the name used in the API URL (such as pods, namespaces). API kinds are sometimes also called resource types.
- API resource: a single instance of an API kind (such as pod, secret).
- Object: a resource that serves as a "record of intent". An object is a desired state for a specific part of your cluster, which the Kubernetes control plane tries to maintain. All objects in the Kubernetes API are also resources.

For clarity, you can add "resource" or "object" when referring to an API resource in Kubernetes documentation. An example: write "a Secret object" instead of "a Secret". If it is clear just from the capitalization, you don't need to add the extra word.

Consider rephrasing when that change helps avoid misunderstandings. A common situation is when you want to start a sentence with an API kind, such as “Secret”; because English and other languages capitalize at the start of sentences, readers cannot tell whether you mean the API kind or the general concept. Rewording can help.

Always format API resource names using UpperCamelCase, also known as PascalCase. Do not write API kinds with code formatting.

Don't split an API object name into separate words. For example, use PodTemplateList, not Pod Template List.

For example:

- Use "Pod" not "pod"
- Use "StatefulSet" not "statefulset" or "stateful set"
- Use "PodDisruptionBudget" or "PDB" not "Pod Disruption Budget"

## Scripts/Commands

This section provides guidelines related to the commands and scripts learners are instructed to use during the workshop content.

### Command blocks

All commands to the executed by the user should be contained within a Markdown `code` block specifying the language as `bash`. This is being used by tools like automated testing so must be consistent.

For example instead of this:

````markdown
```
$ kubectl get pods
```
````

It is preferable to use this:

````markdown
```bash
$ kubectl get pods
```
````

<!-- markdownlint-disable MD038 -->

Enter the command exactly as it should be run by the learner, prefixed with `$ `.

For example instead of this:

````markdown
```bash
[root@b32a35acd6b6 /]$ kubectl get pods
```
````

You should do this:

````markdown
```bash
$ kubectl get pods
```
````

Expected output from a command the learner runs can be displayed under the command, do not prefix it with anything:

````markdown
Please run this command:

```bash
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS      AGE
aws-node-1z3ng             1/1     Running   1 (16h ago)   21h
```
````

### Asynchronous commands

The nature of Kubernetes as a declarative system means that often commands can be run that alter the state of the cluster and return immediately while the state is reconciled. Examples of this include `kubectl apply` and `helm install`. This can cause a number of issues:

1. Learners may try to immediately interact with the resources being created or modified, which can cause "race conditions"
2. Content can be made more complex by instructing the learner to "wait" or repeatedly run commands to check the state of the resources
3. No immediate feedback in the case of errors

As much as possible commands that provide some sort of "wait" function should leverage it, or be accompanied by a command that waits for an explicit condition.

For example instead of this:

```bash
$ kubectl apply -f manifest.yaml
[...]
```

It is preferable to use this:

```bash
$ kubectl apply -f manifest.yaml
[...]
$ kubectl wait --for=condition=available --timeout=60s deployment/example
```

Similarly with `helm` use `--wait`:

```bash
$ helm upgrade --install --namespace karpenter \
  karpenter karpenter/karpenter \
  --wait
```

### Referencing Pods

When running `kubectl` commands that reference Pods care should be taken to ensure that it is done in a way that will work in situations where the Pod name might be variable or generated, for example Pods that are created by a `Deployment`.

For example instead of this:

```bash
$ kubectl describe pod example-abc123
```

It is preferable to use this:

```bash
$ kubectl describe pod deployment/example
```

Alternatively, use labels and selectors:

```bash
$ kubectl get pods --selector=app=example
```

### Use of `kubectl exec`

During the course of modules its often necessary to use the `kubectl exec` command to open a shell in a running container. Where possible the content should avoid opening persistent shell sessions to containers and instead bias towards executing discrete commands.

For example, instead of this:

```bash
$ kubectl exec -it deployment/example -- bash
[root@b32a35acd6b6 /]$ curl localhost:8080
Hello!
[root@b32a35acd6b6 /]$ exit
$
```

It is preferable to use this:

```bash
$ kubectl exec -it deployment/example -- curl localhost:8080
Hello!
$
```

### Avoid use of multiple windows/shells

Sometimes it is tempting to execute a long-running command in one window and instruct the learner to open a new shell window to run another command while that is happening. Examples of this include generating load while watching a Deployment scale horizontally. Use of this approach should be avoided as much as possible for a number of reasons:

1. It can be confusing for the learner to switch between multiple windows
2. Contextual information like environment variables can get lost in new windows
3. It is more difficult to test

### Referencing external manifests or components

If something like a manifest hosted externally is to be referenced by content it should be pinned as explicitly as possible to prevent changes to these files causing uncontrolled changes to the content experience, or worse breaking it entirely.

When fetching a manifest from GitHub do not refer to `master` or `main` and instead refer to either a tag or specific commit.

For example, instead of this:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml
```

It is preferable to use this:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/v0.0.86/stable/aws-load-balancer-controller/crds/crds.yaml
```

Notice we changed from referring to `master` to referring to the tag `v0.0.86`.

### Referencing existing AWS infrastructure in content

It is common in workshop content to reference various AWS infrastructure that has been build by the Terraform configuration provided. Some examples of this include:

- Getting the cluster name to reference in a Kubernetes manifest
- Modifying EKS managed node group configuration by name

Names of these resources should NOT be hardcoded in content, as even though the default name is predictable the content is designed in a way to make it possible to have multiple instances of the workshop infrastructure in a single AWS account and region.

The recommendation is to use the EKS cluster name where possible, and this is provided by default in the learning environment with the environment variable `EKS_CLUSTER_NAME`. This is always set, and does not need to be looked up each time.

An example of using this would look like so:

```bash
$ aws eks describe-cluster --name $EKS_CLUSTER_NAME
```

### Securing ingress traffic

Many labs require an endpoints for particular workloads be exposed to the public Internet, such as the retail sample application or system components like ArgoCD. Its common for organizations to flag endpoints on the public Internet for security reasons, so it is necessary to provide an option to restrict access to these endpoints.

There is a `InboundCIDR` configuration setting available to workshop users through the CloudFormation template used to deploy the IDE, which defaults to `0.0.0.0/0`. This can be used to provide a custom CIDR that should be applied to any public-facing endpoint creating in workshop material.

This is made available in the IDE via the `INBOUND_CIDRS` environment variable, which is a comma-separated list of CIDR ranges that includes:

1. The `InboundCIDR` value
2. The public IP address of the IDE
3. The public IP address of the NAT gateway in the EKS cluster VPC

This value is also made available in Terraform modules for labs via the `inbound_cidrs` TF variable.

There are several common patterns to apply this.

#### Creating an Ingress resource via YAML

Use the `alb.ingress.kubernetes.io/inbound-cidrs` annotation:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ui
  namespace: ui
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/liveness
    alb.ingress.kubernetes.io/inbound-cidrs: $INBOUND_CIDRS
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ui
                port: 80
```

Ensure that the value is populated with `envsubst` in the instructions to the user:

```bash
$ cat ingress.yaml | envsubst | kubectl apply -f -
```

#### Creating a LoadBalancer service resource via YAML

Use the `service.beta.kubernetes.io/load-balancer-source-ranges` annotation:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ui-nlb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
    service.beta.kubernetes.io/load-balancer-source-ranges: $INBOUND_CIDRS
  namespace: ui
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
      name: http
  selector:
    app.kubernetes.io/name: ui
    app.kubernetes.io/instance: ui
    app.kubernetes.io/component: service
```

Ensure that the value is populated with `envsubst` in the instructions to the user:

```bash
$ cat service.yaml | envsubst | kubectl apply -f -
```

#### Creating a load balancer via lab Terraform

For labs where provisioning the load balancer is done in the initial setup this can be done in Terraform by using the appropriate annotation mentioned above and combining it with the `inbound_cidrs` variable which will be populated automatically:

```hcl
resource "kubernetes_manifest" "ui_nlb" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "name"      = "ui-nlb"
      "namespace" = "ui"
      "annotations" = {
        "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
        "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
        "service.beta.kubernetes.io/load-balancer-source-ranges"       = var.inbound_cidrs
      }
    }
    "spec" = {
      "type" = "LoadBalancer"
      "ports" = [{
        "port"       = 80
        "targetPort" = 8080
        "name"       = "http"
      }]
      "selector" = {
        "app.kubernetes.io/name"      = "ui"
        "app.kubernetes.io/instance"  = "ui"
        "app.kubernetes.io/component" = "service"
      }
    }
  }
}
```

#### Creating a load balancer via a Helm chart

Components like ArgoCD are installed with their Helm charts, and if a public load balancer is required can be configured appropriately via the `values.yaml` and `--set` flags. The `INBOUND_CIDRS` environment variable MUST be escaped first.

For example:

```bash
$ ESCAPED_CIDRS="${INBOUND_CIDRS//,/\\,}"
$ helm upgrade --install argocd argo-cd/argo-cd --version "${ARGOCD_CHART_VERSION}" \
  --namespace "argocd" --create-namespace \
  --values ~/environment/eks-workshop/modules/automation/gitops/argocd/values.yaml \
  --set "server.service.annotations.service\\.beta\\.kubernetes\\.io/load-balancer-source-ranges=$ESCAPED_CIDRS" \
  --wait
```

Where the `values.yaml` file contains the rest of the load balancer configuration:

```yaml
server:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: external
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
```
