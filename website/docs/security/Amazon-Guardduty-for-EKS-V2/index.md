---
title: "Amazon GuardDuty for EKS"
sidebar_position: 120
sidebar_custom_props: {"module": true}
---

Amazon GuardDuty for EKS Protection monitors control plane activity by analyzing Kubernetes audit logs from existing and new Amazon EKS clusters in your accounts. GuardDuty is integrated with Amazon EKS, giving it direct access to the Kubernetes audit logs without requiring you to turn on or store these logs. Once a threat is detected, GuardDuty generates a security finding that includes container details such as pod ID, container image ID, and associated tags.

At launch, GuardDuty for EKS Protection includes 27 new GuardDuty finding types that can help detect threats related to user and application activity captured in Kubernetes audit logs
