---
title: "Creating Amazon Managed Grafana Workspace"
sidebar_position: 40
---

#### Prerequisite

AMG requires AWS SSO / SAML for authentication. 

Follow the  [AMG Integration with Okta](https://docs.aws.amazon.com/grafana/latest/userguide/AMG-SAML-providers-okta.html) documentation to configure Amazon Managed Grafana to use Okta as an identity provider.

As part of the lab setup, we have created a Amazon Managed Grafana workspace named `eksworkshop-grafana`


Once the above setup is complete, you should be able to login to the Amazon Managed Grafana workspace using Okta authentication