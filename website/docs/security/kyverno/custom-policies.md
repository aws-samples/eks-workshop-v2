---
title: "Testing Custom Policies using Kyverno CLI"
sidebar_position: 138
---

Writing & Validating Custom Kyverno Policies can be challenging at times. So far in the lab, we have directly applied  Kyverno Policies to our EKS Clusters. It’s not always optimal to test policy evaluation in Kubernetes clusters. It’s cheaper (time and money) to catch potential policy issues (violations, errors, etc.) upstream of Kubernetes in an automated DevOps pipeline. To shift policy testing to the left (for less cost and overhead), before we touch our clusters, we can use the Kyverno command-line interface (CLI) to apply policies to Kubernetes resource YAML files.

There are multiple ways to install the Kyverno CLI. In this lab, we will do binary installation.

```
curl -LO https://github.com/kyverno/kyverno/releases/download/v1.7.2/kyverno-cli_v1.7.2_linux_x86_64.tar.gz
tar -xvf kyverno-cli_v1.7.2_linux_x86_64.tar.gz
sudo cp kyverno /usr/local/bin/
```

```
kyverno version
```

```text
Version: 1.7.2
Time: 2022-07-25T06:08:46Z
Git commit ID: 420ac57541a3767f052d57044f636b17d9e0c346
```

Kyverno CLI has multiple commands such as ```Apply, Test & JP```. In our lab, we will perform **Apply** command.

The ```apply``` command is used to perform a ```dry run``` on one or more policies with a given set of input resources. This can be useful to determine a policy’s effectiveness prior to committing to a cluster. In the case of mutate policies, the apply command can show the mutated resource as an output. The input resources can either be resource manifests (one or multiple) or can be taken from a running Kubernetes cluster. The apply command supports files from URLs both as policies and resources. Once the Kyverno CLI is installed, the following command can be used to apply a Kyverno policy to a Kubernetes resource YAML file (no Kubernetes cluster needed).

We will just try out our sample policies & Deployments created throughout the workshop. Below, we are using the Generic Pod & BlockIamges Policy.

```
kyverno apply blockimages.yaml --resource pod.yaml 
```

Sample Output:
```
Applying 1 policy to 2 resources... 
(Total number of result count may vary as the policy is mutated by Kyverno. To check the mutated policy please try with log level 5)

policy restrict-image-registries -> resource default/Pod/efs-app failed: 
1. validate-registries: validation error: Unknown Image registry. Rule validate-registries failed at path /spec/containers/0/image/ 

pass: 0, fail: 1, warn: 0, error: 0, skip: 5 
```

In the above example, we didn't deploy the Pod & neither the Kyverno Policy, and were able to test out the effectiveness of the Policy on our Application Manifests. 

You can perform similar checks for a single Manifests across multiple Policies in a single command, and more other combinations. Refer [here](https://kyverno.io/docs/kyverno-cli/#cli-commands) for more details.
