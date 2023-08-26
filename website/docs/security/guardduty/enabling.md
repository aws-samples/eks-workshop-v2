---
title: "Enable GuardDuty findings on EKS"
sidebar_position: 121
---


In this lab, we'll enable GuardDuty and Kubernetes protection.

**Enabling using CLI:**

```bash test=false
$ aws guardduty create-detector --enable --data-sources Kubernetes={AuditLogs={Enable=true}}
{
    "DetectorId": "b6b992d6d2f48e64bc59180bfexample"
}
```

**Enabling using Console:**
Search for GuardDuty in AWS console

![](assets/Gsearch.png)

Click Get Started

![](assets/gpage.png)

Click **Enable GuardDuty**

![](assets/genable.png)

Double check that Kubernetes Protection is enabled and go to Findings. You should find that there are no findings available yet.
![](assets/gkubernetesenable.png)
