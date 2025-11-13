---
title: Sample Application Overview
sidebar_position: 40
---

# Sample Application Overview

The EKS workshop uses a sample application designed to illustrate various concepts related to containers on AWS. It models a sample retail store application, where customers can browse product catalog, add items to their cart and complete the order through the checkout process.

You can find the full source code for the sample application on [GitHub](https://github.com/aws-containers/retail-store-sample-app).

<Browser url="-">
<img src={require('@site/static/img/sample-app-screens/home.webp').default}/>
</Browser>

## Application Architecture

The application follows a microservices architecture with several independent components:

<img src={require('@site/static/img/sample-app-screens/architecture.webp').default}/>

| Component | Description                                                                                   |
| --------- | --------------------------------------------------------------------------------------------- |
| UI        | Provides the front end user interface and aggregates API calls to the various other services. |
| Catalog   | API for product listings and details                                                          |
| Cart      | API for customer shopping carts                                                               |
| Checkout  | API to orchestrate the checkout process                                                       |
| Orders    | API to receive and process customer orders                                                    |

## Packaging the components

Before a workload can be deployed to a Kubernetes distribution like EKS it first must be packaged as a container image and published to a container registry. Basic container topics like this are not covered as part of this workshop, and the sample application has container images already available in Amazon Elastic Container Registry for the labs we'll complete today.

The table below provides links to the ECR Public repository for each component, as well as the `Dockerfile` that was used to build each component.

| Component     | ECR Public repository                                                             | Dockerfile                                                                                                  |
| ------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| UI            | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui)       | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/ui/Dockerfile)       |
| Catalog       | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-catalog)  | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/catalog/Dockerfile)  |
| Shopping cart | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-cart)     | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/cart/Dockerfile)     |
| Checkout      | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-checkout) | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/checkout/Dockerfile) |
| Orders        | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-orders)   | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/orders/Dockerfile)   |

Initially we'll deploy the application in a manner that is self-contained in the Amazon EKS cluster, without using any AWS services like load balancers or a managed database. Over the course of the labs we'll leverage different features of EKS to take advantage of broader AWS services and features for our retail store.

