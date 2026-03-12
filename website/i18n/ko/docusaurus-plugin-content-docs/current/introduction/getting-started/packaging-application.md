---
title: 컴포넌트 패키징
sidebar_position: 20
tmdTranslationSourceHash: 48eb52800a66944b2465d3a51197051c
---

워크로드를 EKS와 같은 Kubernetes 배포판에 배포하기 전에 먼저 컨테이너 이미지로 패키징하고 컨테이너 레지스트리에 게시해야 합니다. 이러한 기본 컨테이너 주제는 이 워크샵에서 다루지 않으며, 샘플 애플리케이션은 오늘 진행할 실습을 위해 Amazon Elastic Container Registry에서 이미 사용 가능한 컨테이너 이미지를 제공합니다.

아래 표는 각 컴포넌트의 ECR Public 리포지토리와 각 컴포넌트를 빌드하는 데 사용된 `Dockerfile`에 대한 링크를 제공합니다.

| 컴포넌트      | ECR Public 리포지토리                                                             | Dockerfile                                                                                                  |
| ------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| UI            | [리포지토리](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui)       | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/ui/Dockerfile)       |
| Catalog       | [리포지토리](https://gallery.ecr.aws/aws-containers/retail-store-sample-catalog)  | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/catalog/Dockerfile)  |
| Shopping cart | [리포지토리](https://gallery.ecr.aws/aws-containers/retail-store-sample-cart)     | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/cart/Dockerfile)     |
| Checkout      | [리포지토리](https://gallery.ecr.aws/aws-containers/retail-store-sample-checkout) | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/checkout/Dockerfile) |
| Orders        | [리포지토리](https://gallery.ecr.aws/aws-containers/retail-store-sample-orders)   | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/v1.2.1/src/orders/Dockerfile)   |

