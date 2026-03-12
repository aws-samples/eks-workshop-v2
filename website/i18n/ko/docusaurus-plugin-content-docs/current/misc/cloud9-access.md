---
title: Cloud9 액세스
tmdTranslationSourceHash: 531af73488b9730348b586ec9ebd39ba
---

Terraform 스크립트를 실행한 후 **eks-workshop**이라는 이름의 Cloud9 인스턴스가 보이지 않는 경우 다음을 수행하세요:

Environments 드롭다운을 변경하여 **All account environments**를 표시합니다.
![Environments 드롭다운을 변경하여 **All account environments**를 표시](/docs/misc/cloud9-environments.webp)
**Cloud9 IDE** 아래에서 **Open**을 클릭합니다.

Open 링크가 작동하지 않는 경우, Cloud9 인스턴스에 대한 사용자 액세스 권한을 부여해야 합니다.

AWS CLI에서 다음 코드를 수정하여 사용자에게 Cloud9 인스턴스에 대한 액세스 권한을 부여하세요:

```shell
aws cloud9 create-environment-membership --environment-id environment_id_from_arn  --user-arn arn:aws:sts::1234567890:assumed-role/Admin/somerole --permissions read-write
```

다음 두 가지를 교체해야 합니다:

```text
arn:aws:sts::1234567890:assumed-role/Admin/somerole
```

위의 arn은 Cloud9 인스턴스에 액세스해야 하는 사용자 또는 역할의 arn으로 교체해야 합니다.

```text
environment_id_from_arn
```

environment_id_from_arn은 관리하려는 인스턴스의 arn에서 environment-id로 교체해야 합니다. arn은 인스턴스 이름을 클릭하면 찾을 수 있습니다. arn의 마지막 콜론 뒤의 모든 내용이 environment-id입니다.

![cloud9-arn](/docs/misc/cloud9-arn.webp)

교체된 텍스트로 코드를 CLI에 입력하면 이제 Cloud9 인스턴스에 액세스할 수 있습니다.

```shell
$ aws cloud9 create-environment-membership --environment-id environment_id_from_arn  --user-arn arn:aws:sts::1234567890:assumed-role/Admin/somerole --permissions read-write
{
    "membership": {
        "permissions": "read-write",
        "userId": "XXXXXXXXXXXXXXXXXXX:someone",
        "userArn": "arn:aws:sts::111111111111:assumed-role/Admin/someone",
        "environmentId": "environment_id_from_arn",
        "lastAccess": "2023-04-07T09:27:56-04:00"

}
```

