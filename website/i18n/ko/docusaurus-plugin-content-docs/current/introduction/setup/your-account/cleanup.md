---
title: 정리하기
sidebar_position: 90
tmdTranslationSourceHash: b50eea77a7ff66e51772b8b1062a1d97
---

:::caution

다음 단계로 진행하기 전에 랩 EKS 클러스터를 프로비저닝하는 데 사용한 메커니즘에 대한 각각의 정리 지침을 실행했는지 확인하세요:

- [eksctl](./using-eksctl.md)
- [Terraform](./using-terraform.md)

:::

이 섹션에서는 랩을 실행하는 데 사용한 IDE를 정리하는 방법을 설명합니다.

먼저 CloudFormation 스택을 배포한 리전에서 CloudShell을 엽니다:

<ConsoleButton url="https://console.aws.amazon.com/cloudshell/home" service="console" label="CloudShell 열기"/>

그런 다음 다음 명령을 실행하여 CloudFormation 스택을 삭제합니다:

```bash test=false
$ aws cloudformation delete-stack --stack-name eks-workshop-ide
```

스택이 삭제되면 IDE와 관련된 모든 리소스가 AWS 계정에서 제거되어 추가 요금이 발생하지 않습니다.

