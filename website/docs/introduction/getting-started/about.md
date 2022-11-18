---
title: Sample application
sidebar_position: 20
---

Most of the labs in this workshop use a common sample application to provide actual container components that we can work on during the exercises. The sample application models a simple web store application, where customers can browse a catalogue, add items to their cart and complete a purchase.

<browser url="-">
<img src={require('@site/static/img/sample-app-screens/home.png').default}/>
</browser>

The application has several components and dependencies:

![Architecture](https://github.com/niallthomson/microservices-demo/raw/master/docs/images/architecture.png)

Initially we will deploy the application in a manner that is self-contained in the Amazon EKS cluster, without using any AWS services like load balancers or managed database. Over the course of the labs we will leverage different features of EKS to take advantage of broader AWS services and features for our retail store.