---
title: "Cleanup"
sidebar_position: 44
---

To disable GuardDuty run the following command:

```bash test=false
$ aws guardduty list-detectors --output text --query DetectorIds | xargs aws guardduty delete-detector  --detector-id
```
