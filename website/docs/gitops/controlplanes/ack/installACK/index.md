---
title: "Configuring ACK Resources"
sidebar_position: 1
weight: 20
---

Installing a controller consists of three steps:
1. Setup of Iam Role Service Account (IRSA) for the controller. It gives the controller the access rights to the AWS resources it controls.
2. Setup the controller K8S resources via Helm
3. Update the SA annotation to have the IRSA working and restart the controller (to simplify)

The first controller to setup is the IAM one which is going to be used for the step 1 for the other controllers.

## IAM controller setup

## RDS controller setup

## MQ controller setup