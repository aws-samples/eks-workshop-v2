---
title: 레거시 랩 환경 마이그레이션
tmdTranslationSourceHash: 14050535b3534184f1640b7b062812cc
---

2023년 7월 21일 EKS Workshop은 인프라 프로비저닝 방식과 관련하여 몇 가지 주요 변경 사항을 거쳤습니다. 이전에는 워크샵이 시작하기 전에 Terraform을 사용하여 모든 인프라를 프로비저닝했지만, 초기 시작 시 발생할 수 있는 문제의 수를 줄이기 위해 변경하기로 결정했습니다. 이제 워크샵 인프라는 간소화된 초기 설정과 함께 점진적으로 구축됩니다.

Terraform 기반의 레거시 메커니즘을 통해 프로비저닝된 랩 환경이 있는 경우 이 새로운 프로비저닝 메커니즘으로 마이그레이션해야 합니다. 아래 단계는 기존 환경을 정리하기 위한 가이드를 제공합니다.

먼저 Cloud9 IDE에 액세스하고 다음을 실행하여 클러스터에서 실행 중인 샘플 애플리케이션을 정리합니다. 이는 Terraform이 EKS 클러스터와 VPC를 정리할 수 있도록 하는 데 필요합니다:

```bash test=false
$ delete-environment
```

다음으로 Terraform으로 프로비저닝된 AWS 리소스를 삭제해야 합니다. 처음에 클론한 Git 리포지토리에서(예: 로컬 머신에서) 다음 명령을 실행합니다:

```bash test=false
$ cd terraform
$ terraform destroy -target=module.cluster.module.eks_blueprints_kubernetes_addons --auto-approve
# To delete the descheduler add-on, run the following command:
$ terraform destroy -target=module.cluster.module.descheduler --auto-approve
# To delete the core blueprints add-ons, run the following command:
$ terraform destroy -target=module.cluster.module.eks_blueprints --auto-approve
# To delete the remaining resources created by Terraform, run the following command:
$ terraform destroy --auto-approve
```

이제 [여기에 설명된](/docs/introduction/setup/your-account) 단계를 따라 새 랩 환경을 생성할 수 있습니다.

