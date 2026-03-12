---
title: "Add-ons"
sidebar_position: 20
tmdTranslationSourceHash: 'e8980a5b478431de18d3b9ead0981b91'
---

EKS add-ons를 사용하면 Kubernetes 애플리케이션에 핵심 기능을 제공하는 운영 소프트웨어 또는 add-ons를 구성, 배포 및 업데이트할 수 있습니다. 이러한 add-ons에는 Amazon VPC CNI와 같은 클러스터 네트워킹을 위한 중요한 도구뿐만 아니라 관측 가능성, 관리, 확장 및 보안을 위한 운영 소프트웨어가 포함됩니다. add-on은 기본적으로 Kubernetes 애플리케이션에 운영 기능을 제공하지만 애플리케이션에 특정하지 않은 소프트웨어입니다.

**[Amazon EKS add-ons](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)**는 Amazon EKS 클러스터를 위한 선별된 add-ons 세트의 설치 및 관리를 제공합니다. 모든 Amazon EKS add-ons에는 최신 보안 패치, 버그 수정이 포함되어 있으며 AWS에서 Amazon EKS와 함께 작동하도록 검증되었습니다. Amazon EKS add-ons를 사용하면 Amazon EKS 클러스터가 안전하고 안정적으로 유지되도록 일관되게 보장할 수 있으며 add-ons를 설치, 구성 및 업데이트하는 데 필요한 작업량을 줄일 수 있습니다.

Amazon EKS API, AWS Management Console, AWS CLI 및 eksctl을 사용하여 Amazon EKS add-ons를 추가, 업데이트 또는 삭제할 수 있습니다. [Amazon EKS add-ons 생성](https://aws-ia.github.io/terraform-aws-eks-blueprints-addons/main/amazon-eks-addons/)도 가능합니다. Amazon EKS add-on 구현은 범용적이며 EKS API에서 지원하는 모든 add-on을 배포하는 데 사용할 수 있습니다. 네이티브 EKS addons 또는 AWS Marketplace를 통해 제공되는 타사 add-ons 모두 가능합니다.

**Add-ons** 탭으로 이동하면 이미 설치된 add-ons를 검색할 수 있습니다.

![Insights](/img/resource-view/find-add-ons.jpg)

또는 'Get more add-ons'를 선택하여 추가 add-ons를 선택하거나 AWS MarketPlace add-ons를 검색하여 클러스터를 향상시킬 수 있습니다.

![Insights](/img/resource-view/select-add-ons.jpg)

