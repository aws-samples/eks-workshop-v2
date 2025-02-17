---
title: 컴포넌트 패키징
sidebar_position: 20
---

EKS와 같은 Kubernetes 배포판에 워크로드를 배포하기 전에, 먼저 컨테이너 이미지로 패키징하고 컨테이너 레지스트리에 게시해야 합니다. 이러한 기본적인 컨테이너 주제는 이 워크샵에서 다루지 않으며, 오늘 완료할 실습을 위한 샘플 애플리케이션의 컨테이너 이미지는 이미 Amazon Elastic Container Registry에서 사용 가능합니다.

아래 표는 각 컴포넌트의 ECR Public 저장소 링크와 각 컴포넌트를 빌드하는 데 사용된 `Dockerfile` 링크를 제공합니다.

| Component     | ECR Public repository                                                             | Dockerfile                                                                                                  |
| ------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| UI            | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui)       | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/0.1.0/images/java17/Dockerfile) |
| Catalog       | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-catalog)  | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/0.1.0/images/go/Dockerfile)     |
| Shopping cart | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-cart)     | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/0.1.0/images/java17/Dockerfile) |
| Checkout      | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-checkout) | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/0.1.0/images/nodejs/Dockerfile) |
| Orders        | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-orders)   | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/0.1.0/images/java17/Dockerfile) |
| Assets        | [Repository](https://gallery.ecr.aws/aws-containers/retail-store-sample-assets)   | [Dockerfile](https://github.com/aws-containers/retail-store-sample-app/blob/0.1.0/src/assets/Dockerfile)    |
