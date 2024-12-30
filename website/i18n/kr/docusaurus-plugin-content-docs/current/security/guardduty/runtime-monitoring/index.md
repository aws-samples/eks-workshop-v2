---
title: "EKS Runtime Monitoring"
sidebar_position: 530
---

EKS Runtime Monitoring provides runtime threat detection coverage for Amazon EKS nodes and containers. It uses the GuardDuty security agent (EKS add-on) that adds runtime visibility into individual EKS workloads, for example, file access, process execution, privilege escalation, and network connections identifying specific containers that may be potentially compromised.

When you enable EKS Runtime Monitoring, GuardDuty can start monitoring the runtime events within your EKS cluster. If your EKS cluster doesn't have security agent deployed either automatically through GuardDuty or manually, GuardDuty will not be able to receive the runtime events of your EKS clusters, meaning that the agent must be deployed on the EKS nodes within your EKS clusters. You can either choose GuardDuty to manage the security agent automatically or you can manage the security agent deployment and updates manually.

In this lab exercise, we'll generate a few EKS runtime findings in your Amazon EKS cluster, listed below.

- `Execution:Runtime/NewBinaryExecuted`
- `CryptoCurrency:Runtime/BitcoinTool.B!DNS`
- `Execution:Runtime/NewLibraryLoaded`
- `DefenseEvasion:Runtime/FilelessExecution`
