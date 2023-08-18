---
title: "Cleanup"
sidebar_position: 133
---

To disable GuardDuty run the following command:

```bash test=false
$ DetectorIds=`aws guardduty list-detectors --output text --query DetectorIds`
$ aws guardduty delete-detector  --detector-id  $DetectorIds
```
