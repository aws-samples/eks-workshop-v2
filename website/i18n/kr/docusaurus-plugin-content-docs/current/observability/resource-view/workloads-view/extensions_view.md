---
title: "CustomResourceDefinitions"
sidebar_position: 70
---

[확장](https://kubernetes.io/docs/concepts/extend-kubernetes/)은 쿠버네티스를 확장하고 깊이 통합하는 소프트웨어 구성 요소입니다. 이 실습에서는 **_Custom Resource Definitions_**, **_Mutating Webhook Configurations_**, **_Validating Webhook Configurations_**를 포함한 일반적인 확장 리소스 유형을 살펴보겠습니다.

**[CustomResourceDefinitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)** API 리소스를 사용하면 사용자 정의 리소스를 정의할 수 있습니다. CRD 객체를 정의하면 사용자가 지정한 이름과 스키마로 새로운 사용자 정의 리소스가 생성됩니다. 쿠버네티스 API는 사용자 정의 리소스의 저장소를 제공하고 처리합니다. CRD 객체의 이름은 유효한 **DNS 서브도메인 이름**이어야 합니다.

**_Resources_** - **_Extensions_**에서 클러스터의 **_Custom Resource Definitions_** 목록을 볼 수 있습니다.

**_Webhook_** 구성은 [_쿠버네티스 Admission 컨트롤러_](https://kubernetes.io/blog/2019/03/21/a-guide-to-kubernetes-admission-controllers/)에 의해 객체 요청을 수락하거나 거부하기 위해 인증된 API 요청을 가로채는 과정에서 실행됩니다. 쿠버네티스 admission 컨트롤러는 네임스페이스 또는 클러스터 전반에 걸쳐 보안 기준선을 설정합니다. 다음 다이어그램은 admission 컨트롤러 프로세스에 포함된 다양한 단계를 설명합니다.

![Insights](/img/resource-view/ext-admincontroller.png)

[Mutating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook)는 사용자 정의 기본값을 적용하기 위해 API 서버로 전송된 객체를 수정합니다.

**_Resources_** - **_Extensions_**에서 클러스터의 **_Mutating Webhook Configurations_** 목록을 볼 수 있습니다.

아래 스크린샷은 _aws-load-balancer-webhook_의 세부 정보를 보여줍니다. 이 webhook 구성에서 `Match policy = Equivalent`는 webhook 버전 `Admission review version = v1beta1`에 따라 객체를 수정하여 요청이 webhook으로 전송됨을 의미합니다.

구성에서 `Match policy = Equivalent`인 경우, 새로운 요청이 처리되지만 구성에 지정된 것과 다른 webhook 버전을 가지고 있다면 요청은 webhook으로 전송되지 않습니다. _Side Effects_가 `None`으로 설정되어 있고 _Timeout Seconds_가 `10`으로 설정되어 있어 이 webhook은 부작용이 없으며 10초 후에 거부됨을 알 수 있습니다.

![Insights](/img/resource-view/ext-mutatingwebhook-detail.jpg)

**[Validating admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#validatingadmissionwebhook)**는 API 서버에 대한 요청을 검증합니다. 구성에는 요청을 검증하기 위한 설정이 포함됩니다. **_ValidatingAdmissionWebhooks_**의 구성은 **_MutatingAdmissionWebhook_**와 유사하지만, **_ValidatingAdmissionWebhooks_** 요청 객체의 최종 상태는 etcd에 저장됩니다.