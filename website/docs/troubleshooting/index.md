---
title: "Troubleshooting Scenarios"
sidebar_position: 1
weight: 40
---

Even with careful planning and preparation, unexpected issues can sometimes arise when working with technology or completing complex tasks. This module provides examples of common troubleshooting scenarios to issues reported to AWS support, along with step-by-step guidance on how to diagnose and resolve the problems.

Keep in mind that we will use previous concepts from the other chapters while going through each scenario.

### These are the scenarios covered in this module

- **AWS Load Balancer Controller**
- **Node not ready (Coming soon)**
- others..

:::info Troubleshooting Methodologies
As you progress through the scenarios, we will be introducing an overview of different troubleshooting methodologies. For example, all our scenarios are based in the **Reproductions method**.

#### Reproductions Method

Systems and applications come in varying sizes and complexities, which means that you cannot always rely on a full-scale reproduction. We recommend starting with a cut-down reproduction, focusing solely on the components involved. There are times where the issue is specific to the environment and there is a combination of factors necessary for it to occur - in this case, you may need a more complex or even full-scale reproduction, but in our experience that is far less common.

Being able to reproduce an issue allows you:

- Observe and experiment in a controlled environment, without affecting users of the system.
- Allows your team to hand over the problem to the team responsible for the failing components, so your team can continue to focus on more pressing matters and mitigation.
- Provide reproduction instructions to the designers or builders of that component, they can perform a deep, targeted investigation.

:::
