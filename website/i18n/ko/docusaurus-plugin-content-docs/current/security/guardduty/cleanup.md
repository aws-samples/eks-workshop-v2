---
title: "정리"
sidebar_position: 600
tmdTranslationSourceHash: '235e84522c8dfdaccaf559adcd80bab1'
---

GuardDuty를 비활성화하려면 다음 명령을 실행하세요:

```bash test=false
$ aws guardduty list-detectors --output text --query DetectorIds | xargs aws guardduty delete-detector  --detector-id
```

