---
title: Major upgrade
---

There are certain releases of the workshop that constitute "major upgrades" that are not backwards compatible. An example of this is upgrading the version of EKS being used, along with other dependencies in the IDE. When this occurs users that have an existing lab environment in their own AWS account must delete and re-create the environment.

Follow the instructions in the [Cleaning Up](/docs/introduction/setup/your-account/cleanup) to delete both the EKS cluster and the Cloud9 IDE.

Next create a fresh environment by following the [In your AWS account](/docs/introduction/setup/your-account) section to create a new Cloud9 IDE and EKS cluster. This will ensure that both of these are updated to reflect the latest versions to align with the content.

:::tip
It is likely that many of the labs will continue to function with your existing lab, but there will be some that may either partially function or leave your environment in an unmaintainable state. It is recommended to follow the steps above.
:::