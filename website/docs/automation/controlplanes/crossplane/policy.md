---
title: "Policy"
sidebar_position: 50
---

## Kubernetes Admission Control

Kubernetes policy and governance refer to the set of practices and tools used to ensure the consistent enforcement and management of policies within a Kubernetes cluster. One approach to implementing policies is through the use of policy engines such as OPA (Open Policy Agent), Gatekeeper, and Kyverno.

OPA is a flexible and general-purpose policy engine that allows users to define and enforce policies across various aspects of a Kubernetes deployment. It provides a declarative language, Rego, for expressing policies and offers a powerful policy evaluation framework.

Gatekeeper is an admission controller for Kubernetes that uses OPA as its policy engine. It enables administrators to define and enforce custom admission policies during the cluster's resource admission process. Gatekeeper helps ensure that only compliant resources are allowed into the cluster, preventing misconfigurations and security vulnerabilities.

Kyverno is another Kubernetes policy engine that specializes in validating and mutating resources. It allows users to define policies in the form of Kubernetes Custom Resource Definitions (CRDs) and enforces them during resource creation and updates. Kyverno's policies can automatically mutate resources to conform to specific requirements.

OPA, Gatekeeper, and Kyverno offer powerful tools for policy and governance in Kubernetes. They enable administrators to define and enforce policies related to security, compliance, resource allocation, and more. By leveraging these tools, organizations can ensure consistent and secure Kubernetes deployments while maintaining control over their infrastructure.

## Crossplane and Kubernetes Policy Engines

Crossplane is an open-source Kubernetes add-on that extends the platform's capabilities to manage cloud infrastructure resources using the same declarative approach. By leveraging the Kubernetes policy and governance tools mentioned earlier, such as OPA, Gatekeeper, and Kyverno, Crossplane can enforce policies on cloud resources provisioned through its infrastructure-as-code approach. For example, Crossplane can integrate with OPA to evaluate policies during the provisioning process, ensuring that the requested cloud resources comply with organizational policies and security standards. Gatekeeper and Kyverno can be used to define and enforce additional policies specific to cloud infrastructure provisioning, ensuring consistent and secure resource configurations across multi-cloud and hybrid cloud environments. By combining the power of Crossplane with Kubernetes policy tools, organizations can achieve a unified policy enforcement mechanism across their entire cloud infrastructure stack.

In these labs, we will demonstrate how Crossplane, an extension to Kubernetes, can leverage the policy and governance capabilities of OPA and Gatekeeper to ensure compliance and security across your cloud infrastructure. By integrating Crossplane with OPA and Gatekeeper, we'll show you how to define and enforce policies that govern the provisioning and configuration of infrastructure resources.

## OPA


Here's a simple example of an OPA Rego policy that can be applied to Crossplane to enforce a size limit on an RDS Instance:

```file
automation/controlplanes/crossplane/policy/opa/db.rego
```


In this policy, we define a package called `crossplane.example`. The policy has a single rule called `deny` that will trigger if the specified conditions are met. The conditions include checking that the resource `kind` is "DBInstance", and the `size` is greater than 20. If these conditions are satisfied, the policy will generate a denial message indicating that the RDS database size exceeds the allowed limit of 20.

This policy can be deployed and enforced by OPA and Gatekeeper within the Crossplane environment. When a user attempts to provision an RDS database resource through Crossplane with a size larger than 20, the policy will be evaluated, and if the conditions are met, the provisioning request will be denied.

Lets use the `opa` to evaluate our policy against different an invalid database specifications (i.e. 30GB).

```file
automation/controlplanes/crossplane/policy/opa/db-invalid.json
```


```bash
$ OPA_POLICY=/workspace/modules/automation/controlplanes/crossplane/policy/opa/db.rego
$ OPA_INPUT=/workspace/modules/automation/controlplanes/crossplane/policy/opa/db-invalid.json
$ opa eval --data $OPA_POLICY --input $OPA_INPUT "data.crossplane.violation[_]" --fail-defined  --format pretty
"database size of 30 GB is larger than limit of 20 GB"
$ echo "Exit Code is $?"
echo "Exit Code is 1"
```

Using a valid database specification (i.e. 10GB) lets use opa to evaluate

```file
automation/controlplanes/crossplane/policy/opa/db-valid.json
```

```bash
$ OPA_POLICY=/workspace/modules/automation/controlplanes/crossplane/policy/opa/db.rego
$ OPA_INPUT=/workspace/modules/automation/controlplanes/crossplane/policy/opa/db-valid.json
$ opa eval --data $OPA_POLICY --input $OPA_INPUT "data.crossplane.violation[_]" --fail-defined  --format pretty
[ ]
$ echo "Exit Code is $?"
echo "Exit Code is 0"
```



More example here https://github.com/crossplane/tbs/blob/master/episodes/14/assets/gatekeeper/constraint-template.yaml
Youtube video on Crossplane and OPA https://www.youtube.com/watch?v=TaF0_syejXc
