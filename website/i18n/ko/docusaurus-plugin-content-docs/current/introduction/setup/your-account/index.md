---
title: AWS 계정에서 실습하기
sidebar_position: 30
tmdTranslationSourceHash: 0771be9fbb8a2646bb579605cbec1de9
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

:::danger 경고
AWS 계정에 이 워크샵 환경을 프로비저닝하면 리소스가 생성되며 **이와 관련된 비용이 발생합니다**. 정리 섹션에서는 추가 요금 발생을 방지하기 위해 이러한 리소스를 제거하는 가이드를 제공합니다.
:::

이 섹션에서는 자신의 AWS 계정에서 실습을 실행하기 위한 환경을 설정하는 방법을 설명합니다.

첫 번째 단계는 제공된 CloudFormation 템플릿을 사용하여 IDE를 생성하는 것입니다. 아래의 AWS CloudFormation 빠른 생성 링크를 사용하여 해당 AWS 리전에서 원하는 템플릿을 시작하세요.

| 리전             | 링크                                                                                                                                                                                                                                                                                                                              |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `us-west-2`      | [Launch](https://us-west-2.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-pdx-f3b3f9f1a7d6a3d0.s3.us-west-2.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF)           |
| `eu-west-1`      | [Launch](https://eu-west-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-dub-85e3be25bd827406.s3.eu-west-1.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF)           |
| `ap-southeast-1` | [Launch](https://ap-southeast-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-sin-694a125e41645312.s3.ap-southeast-1.amazonaws.com/39146514-f6d5-41cb-86ef-359f9d2f7265/eks-workshop-vscode-cfn.yaml&stackName=eks-workshop-ide&param_RepositoryRef=VAR::MANIFESTS_REF) |

이 지침은 위에 나열된 AWS 리전에서 테스트되었으며 수정 없이 다른 리전에서 작동한다는 보장은 없습니다.

:::warning

워크샵 자료의 특성상 IDE EC2 인스턴스는 계정에서 광범위한 IAM 권한이 필요합니다. 예를 들어 IAM role을 생성하는 권한 등이 포함됩니다. 계속하기 전에 CloudFormation 템플릿에서 IDE 인스턴스에 제공될 IAM 권한을 검토하세요.

우리는 IAM 권한을 지속적으로 최적화하고 있습니다. 개선을 위한 제안 사항이 있으시면 [GitHub issue](https://github.com/aws-samples/eks-workshop-v2/issues)를 생성해 주세요.

:::

화면 하단으로 스크롤하여 IAM 알림을 확인합니다:

![acknowledge IAM](/docs/introduction/setup/your-account/acknowledge-iam.webp)

그런 다음 **Create stack** 버튼을 클릭합니다:

![Create Stack](/docs/introduction/setup/your-account/create-stack.webp)

CloudFormation 스택이 배포되는 데 약 5분이 걸리며, 완료되면 **Outputs** 탭에서 계속 진행하는 데 필요한 정보를 확인할 수 있습니다:

![cloudformation outputs](/docs/introduction/setup/your-account/vscode-outputs.webp)

`IdeUrl` 출력에는 IDE에 액세스하기 위해 브라우저에 입력할 URL이 포함되어 있습니다. `IdePasswordSecret`에는 IDE용으로 생성된 비밀번호가 포함된 AWS Secrets Manager 시크릿에 대한 링크가 포함되어 있습니다.

비밀번호를 확인하려면 `IdePasswordSecret` URL을 열고 **Retrieve** 버튼을 클릭합니다:

![secretsmanager retrieve](/docs/introduction/setup/your-account/vscode-password-retrieve.webp)

그러면 비밀번호를 복사할 수 있습니다:

![password in Secrets Manager](/docs/introduction/setup/your-account/vscode-password-visible.webp)

제공된 IDE URL을 열면 비밀번호를 입력하라는 메시지가 표시됩니다:

![IDE password prompt](/docs/introduction/setup/your-account/vscode-password.webp)

비밀번호를 제출하면 초기 IDE 화면이 표시됩니다:

![IDE initial screen](/docs/introduction/setup/your-account/vscode-splash.webp)

다음 단계는 실습을 수행할 EKS 클러스터를 생성하는 것입니다. 아래 가이드 중 하나를 따라 이 실습의 요구 사항을 충족하는 클러스터를 프로비저닝하세요:

- **(권장)** [eksctl](./using-eksctl.md)
- [Terraform](./using-terraform.md)
- (곧 제공 예정!) CDK

