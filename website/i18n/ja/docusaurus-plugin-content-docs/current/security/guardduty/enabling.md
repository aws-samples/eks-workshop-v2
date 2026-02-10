---
title: "GuardDuty保護をEKSで有効化する"
sidebar_position: 51
tmdTranslationSourceHash: 560a907e12e478a5feec8577419271bb
---

このラボでは、Amazon GuardDuty EKS保護を有効にします。これにより、EKS監査ログモニタリングとEKSランタイムモニタリングの脅威検出カバレッジが提供され、クラスターを保護するのに役立ちます。

EKS監査ログモニタリングは、Kubernetes監査ログを使用して、ユーザー、Kubernetes APIを使用するアプリケーション、およびコントロールプレーンからの時系列のアクティビティをキャプチャし、潜在的に不審なアクティビティを検索します。

EKSランタイムモニタリングは、オペレーティングシステムレベルのイベントを使用して、Amazon EKSノードとコンテナでの潜在的な脅威を検出するのに役立ちます。

AWS CLIを使用してGuardDutyを有効にしましょう:

```bash test=false
$ aws guardduty create-detector --enable --features '[{"Name" : "EKS_AUDIT_LOGS", "Status" : "ENABLED"}, {"Name" : "EKS_RUNTIME_MONITORING", "Status" : "ENABLED", "AdditionalConfiguration" : [{"Name" : "EKS_ADDON_MANAGEMENT", "Status" : "ENABLED"}]}]'
{
    "DetectorId": "1qaz0p2wsx9ol3edc8ik4rfv7ujm5tgb6yhn"
}
```

数分後、EKSクラスター内の`aws-guardduty-agent` Podのデプロイを確認します。

```bash test=false
$ kubectl -n amazon-guardduty get pods
NAME                        READY   STATUS    RESTARTS   AGE
aws-guardduty-agent-h7qg5   1/1     Running   0          58s
aws-guardduty-agent-hgbsg   1/1     Running   0          58s
aws-guardduty-agent-k7x2b   1/1     Running   0          58s
```

その後、GuardDutyコンソールの**検出結果**セクションに移動します:

<ConsoleButton url="https://console.aws.amazon.com/guardduty/home#/findings?macros=current" service="guardduty" label="GuardDutyコンソールを開く"/>

まだ検出結果がないことを確認できるはずです。

![GuardDuty検出結果](/docs/security/guardduty/findings.webp)
