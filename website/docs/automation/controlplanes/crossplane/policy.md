---
title: "Policy"
sidebar_position: 50
---

## Kubernetes Policies

Kubernetes policies are configurations that manage other configurations or runtime behaviors. Kubernetes Dynamic admission controllers can be used to apply policies on API requests and trigger other policy-based workflows. A dynamic admission controller can perform complex checks including those that require retrieval of other cluster resources and external data.

Dynamic Admission Controllers that act as flexible policy engines are being developed in the Kubernetes ecosystem. One approach to implementing policies is through the use of policy engines such as [OPA (Open Policy Agent)](https://www.openpolicyagent.org/)/[Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/), and [Kyverno](https://kyverno.io/) both [CNCF](https://www.cncf.io/) projects.

- **OPA** is a flexible and general-purpose policy engine that allows users to define and enforce policies across various aspects of a Kubernetes deployment. It provides a declarative language, Rego, for expressing policies and offers a powerful policy evaluation framework.
- **Gatekeeper** is an admission controller for Kubernetes that uses OPA as its policy engine. It enables administrators to define and enforce custom admission policies during the cluster's resource admission process. Gatekeeper helps ensure that only compliant resources are allowed into the cluster, preventing misconfigurations and security vulnerabilities.
- **Kyverno*** is another Kubernetes policy engine that specializes in validating and mutating resources. It allows users to define policies in the form of Kubernetes Custom Resource Definitions (CRDs) and enforces them during resource creation and updates. Kyverno's policies can automatically mutate resources to conform to specific requirements.

## Crossplane and Kubernetes Policy Engines

Crossplane is an open-source Kubernetes add-on that extends the platform's capabilities to manage cloud infrastructure resources using the same declarative approach. By leveraging the Kubernetes policy and governance tools mentioned earlier, such as OPA, Gatekeeper, and Kyverno, Crossplane can enforce policies on cloud resources provisioned through its infrastructure-as-code approach. For example, Crossplane can integrate with OPA to evaluate policies during the provisioning process, ensuring that the requested cloud resources comply with organizational policies and security standards. Gatekeeper and Kyverno can be used to define and enforce additional policies specific to cloud infrastructure provisioning, ensuring consistent and secure resource configurations across multi-cloud and hybrid cloud environments. By combining the power of Crossplane with Kubernetes policy tools, organizations can achieve a unified policy enforcement mechanism across their entire cloud infrastructure stack.


## OPA


Here's a simple example of an OPA Rego policy that can be applied to Crossplane to enforce a size limit on an RDS Instance:

```file
automation/controlplanes/crossplane/policy/opa/db.rego
```



In this policy, we define a package called `crossplane.example`. The policy has a single rule called `deny` that will trigger if the specified conditions are met. The conditions include checking that the resource `kind` is "DBInstance", and the `size` is greater than 20. If these conditions are satisfied, the policy will generate a denial message indicating that the RDS database size exceeds the allowed limit of 20.

This policy can be deployed and enforced by OPA and Gatekeeper within the Crossplane environment. When a user attempts to provision an RDS database resource through Crossplane with a size larger than 20, the policy will be evaluated, and if the conditions are met, the provisioning request will be denied.

Lets use the `opa` to evaluate our policy against different an invalid database specifications.

### Test Invalid DB with opa

Using a invalid database specification (i.e. 30GB) lets use opa to evaluate

```file
automation/controlplanes/crossplane/policy/opa/db-invalid.json
```


```bash
$ OPA_POLICY=/workspace/modules/automation/controlplanes/crossplane/policy/opa/db.rego
$ OPA_INPUT=/workspace/modules/automation/controlplanes/crossplane/policy/opa/db-invalid.json
$ opa eval --data $OPA_POLICY --input $OPA_INPUT "data.crossplane.violation[_]" --fail-defined  --format pretty
"database size of 30 GB is larger than limit of 20 GB"
$ echo "Exit Code is $?"
"Exit Code is 1"
```

You should see a violation message **database size of 30 GB is larger than limit of 20 GB** indicating that the database specification is not
allowed based on the OPA policy. The `opa` CLI should return an exit code of none zero as indicated by the message **Exit Code is 1**


### Test Valid DB with opa

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
"Exit Code is 0"
```

You should shoud not see a violation message indicating that the database specification is allowed based on the OPA policy. The `opa` CLI should return an exit code of zero as indicated by the message **Exit Code is 0**

## Gatekeeper

```bash test=false
$ GATOR_CLI="/workspace/modules/automation/controlplanes/crossplane/policy/gatekeeper/gator"
$ GATOR_TEST="/workspace/modules/automation/controlplanes/crossplane/policy/gatekeeper/managed-resource/"
$ $GATOR_CLI verify $GATOR_TEST -v

```

### Resources
- [Crossplane Examples with OPA and Gatekeeper](https://github.com/crossplane/tbs/tree/master/episodes/14/assets)
- [Youtube video on Crossplane and OPA](https://www.youtube.com/watch?v=TaF0_syejXc)
