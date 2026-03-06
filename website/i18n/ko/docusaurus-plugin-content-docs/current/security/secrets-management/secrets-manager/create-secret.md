---
title: "AWS Secrets Manager에 시크릿 저장하기"
sidebar_position: 421
tmdTranslationSourceHash: 79c2f7e05f509c4c927aa053c5ff1043
---

AWS CLI를 사용하여 AWS Secrets Manager에 시크릿을 생성하는 것부터 시작하겠습니다. 사용자 이름과 비밀번호 값이 포함된 JSON 인코딩 자격 증명이 포함된 시크릿을 생성하겠습니다:

```bash
$ export SECRET_SUFFIX=$(openssl rand -hex 4)
$ export SECRET_NAME="$EKS_CLUSTER_NAME-catalog-secret-${SECRET_SUFFIX}"
$ aws secretsmanager create-secret --name "$SECRET_NAME" \
  --secret-string '{"username":"catalog", "password":"dYmNfWV4uEvTzoFu"}' --region $AWS_REGION
{
    "ARN": "arn:aws:secretsmanager:us-west-2:1234567890:secret:eks-workshop-catalog-secret-WDD8yS",
    "Name": "eks-workshop-catalog-secret-WDD8yS",
    "VersionId": "7e0b352d-6666-4444-aaaa-cec1f1d2df1b"
}
```

:::note
계정에 존재하는 다른 시크릿과 충돌하지 않도록 `openssl`을 사용하여 시크릿 이름에 고유한 접미사를 생성하고 있습니다.
:::

[AWS Secrets Manager 콘솔](https://console.aws.amazon.com/secretsmanager/listsecrets)을 확인하거나 AWS CLI를 사용하여 시크릿이 성공적으로 생성되었는지 확인할 수 있습니다. CLI를 사용하여 시크릿의 메타데이터를 살펴보겠습니다:

```bash
$ aws secretsmanager describe-secret --secret-id "$SECRET_NAME"
{
    "ARN": "arn:aws:secretsmanager:us-west-2:1234567890:secret:eks-workshop-catalog-secret-WDD8yS",
    "Name": "eks-workshop-catalog-secret-WDD8yS",
    "LastChangedDate": "2023-10-10T20:44:51.882000+00:00",
    "VersionIdsToStages": {
        "94d1fe43-87f5-42fb-bf28-f6b090f0ca44": [
            "AWSCURRENT"
        ]
    },
    "CreatedDate": "2023-10-10T20:44:51.439000+00:00"
}
```

이제 AWS Secrets Manager에 시크릿을 성공적으로 생성했으므로 다음 섹션에서 Kubernetes 애플리케이션에서 사용하겠습니다.

