---
title: "CustomResourceDefinitions"
sidebar_position: 70
tmdTranslationSourceHash: '0a0ac67f3a73f687ee714b7b9dc9f2b5'
---

[Extensions](https://kubernetes.io/docs/concepts/extend-kubernetes/)는 Kubernetes를 확장하고 깊이 통합하는 소프트웨어 컴포넌트입니다. 이 실습에서는 **_Custom Resource Definitions_**, **_Mutating Webhook Configurations_**, **_Validating Webhook Configurations_**를 포함한 일반적인 확장 리소스 타입을 살펴보겠습니다.

**[CustomResourceDefinitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)** API 리소스를 사용하면 사용자 정의 리소스를 정의할 수 있습니다. CRD 객체를 정의하면 사용자가 지정한 이름과 스키마를 가진 새로운 사용자 정의 리소스가 생성됩니다. Kubernetes API는 사용자 정의 리소스의 스토리지를 제공하고 처리합니다. CRD 객체의 이름은 유효한 **DNS 서브도메인 이름**이어야 합니다.

**_Resources_** - **_Extensions_** 아래에서 클러스터의 **_Custom Resource Definitions_** 목록을 볼 수 있습니다.

**_Webhook_** 구성은 인증된 API 요청을 가로채서 객체 요청을 수락하거나 거부하는 _[Kubernetes Admission controllers](https://kubernetes.io/blog/2019/03/21/a-guide-to-kubernetes-admission-controllers/)_ 프로세스 중에 실행됩니다. Kubernetes admission controllers는 네임스페이스 또는 클러스터 전체에 보안 기준선을 설정합니다. 다음 다이어그램은 admission controller 프로세스에 포함된 여러 단계를 설명합니다.

![Insights](/img/resource-view/ext-admincontroller.png)

[Mutating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook)는 사용자 정의 기본값을 적용하기 위해 API 서버로 전송된 객체를 수정합니다.

**_Resources_** - **_Extensions_** 아래에서 클러스터의 **_Mutating Webhook Configurations_** 목록을 볼 수 있습니다.

아래 스크린샷은 _aws-load-balancer-webhook_의 세부 정보를 보여줍니다. 이 webhook 구성에서 `Match policy = Equivalent`로 설정되어 있으며, 이는 요청이 webhook 버전 `Admission review version = v1beta1`에 따라 객체를 수정하여 webhook으로 전송됨을 의미합니다.

구성에서 `Match policy = Equivalent`로 설정되어 있으면 새로운 요청이 처리될 때 구성에 지정된 것과 다른 webhook 버전이 있는 경우, 요청은 webhook으로 전송되지 않습니다. _Side Effects_가 `None`으로 설정되어 있고 _Timeout Seconds_가 `10`으로 설정되어 있어 이 webhook은 부작용이 없으며 10초 후에 거부됩니다.

![Insights](/img/resource-view/ext-mutatingwebhook-detail.jpg)

**[Validating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#validatingadmissionwebhook)**는 API 서버에 대한 요청을 검증합니다. 이들의 구성에는 요청을 검증하는 설정이 포함됩니다. **_ValidatingAdmissionWebhooks_**의 구성은 **_MutatingAdmissionWebhook_**과 유사하지만, **_ValidatingAdmissionWebhooks_** 요청 객체의 최종 상태는 etcd에 저장됩니다.

