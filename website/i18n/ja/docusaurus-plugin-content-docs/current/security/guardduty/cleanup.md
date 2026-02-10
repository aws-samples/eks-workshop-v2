---
title: "クリーンアップ"
sidebar_position: 600
tmdTranslationSourceHash: 235e84522c8dfdaccaf559adcd80bab1
---

GuardDutyを無効にするには、以下のコマンドを実行します：

```bash test=false
$ aws guardduty list-detectors --output text --query DetectorIds | xargs aws guardduty delete-detector  --detector-id
```
