---
title: "애드온"
sidebar_position: 20
---

EKS 애드온을 사용하면 Kubernetes 애플리케이션을 지원하는 주요 기능을 제공하는 운영 소프트웨어 또는 애드온을 구성, 배포 및 업데이트할 수 있습니다. 이러한 애드온에는 Amazon VPC CNI와 같은 클러스터 네트워킹을 위한 중요한 도구와 관찰성, 관리, 확장 및 보안을 위한 운영 소프트웨어가 포함됩니다. 애드온은 기본적으로 Kubernetes 애플리케이션에 대한 지원 운영 기능을 제공하는 소프트웨어이지만 애플리케이션에 특정되지 않습니다.

**[Amazon EKS 애드온](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)**은 Amazon EKS 클러스터를 위한 선별된 애드온 세트의 설치 및 관리를 제공합니다. 모든 Amazon EKS 애드온에는 최신 보안 패치, 버그 수정이 포함되어 있으며 Amazon EKS와 함께 작동하도록 AWS에 의해 검증되었습니다. Amazon EKS 애드온을 사용하면 Amazon EKS 클러스터가 안전하고 안정적인지 일관되게 확인할 수 있으며 애드온을 설치, 구성 및 업데이트하는 데 필요한 작업량을 줄일 수 있습니다.

Amazon EKS API, AWS Management Console, AWS CLI 및 eksctl을 사용하여 Amazon EKS 애드온을 추가, 업데이트 또는 삭제할 수 있습니다. 또한 [Amazon EKS 애드온을 생성](https://aws-ia.github.io/terraform-aws-eks-blueprints-addons/main/amazon-eks-addons/)할 수 있습니다. Amazon EKS 애드온 구현은 일반적이며 EKS API에서 지원하는 모든 애드온을 배포하는 데 사용할 수 있습니다. 네이티브 EKS 애드온이나 AWS Marketplace를 통해 제공되는 타사 애드온 모두 가능합니다.

**애드온** 탭으로 이동하면 이미 설치된 애드온을 검색할 수 있습니다.

![Insights](/img/resource-view/find-add-ons.jpg)

또는 '더 많은 애드온 가져오기'를 선택하여 추가 애드온을 선택하거나 클러스터를 향상시키기 위해 AWS MarketPlace 애드온을 검색할 수 있습니다.

![Insights](/img/resource-view/select-add-ons.jpg)