---
title: "AWS Gateway API Controller"
sidebar_position: 10
tmdTranslationSourceHash: 'c80632213a6b836924dc5324f797c745'
---

Gateway API는 Kubernetes 네트워킹 커뮤니티에서 관리하는 오픈 소스 프로젝트입니다. Kubernetes에서 애플리케이션 네트워킹을 모델링하는 리소스 모음입니다. Gateway API는 GatewayClass, Gateway, Route와 같은 리소스를 지원하며, 많은 벤더에 의해 구현되었고 광범위한 업계 지원을 받고 있습니다.

원래 잘 알려진 Ingress API의 후속 제품으로 구상된 Gateway API의 이점에는 일반적으로 사용되는 많은 네트워킹 프로토콜에 대한 명시적 지원과 Transport Layer Security(TLS)에 대한 긴밀하게 통합된 지원이 포함됩니다(이에 국한되지 않음).

AWS에서는 AWS Gateway API Controller를 통해 Amazon VPC Lattice와 통합하기 위해 Gateway API를 구현합니다. 클러스터에 설치하면 컨트롤러는 Gateway API 리소스(예: Gateway 및 Route)의 생성을 감시하고 아래 이미지의 매핑에 따라 해당 Amazon VPC Lattice 객체를 프로비저닝합니다. AWS Gateway API Controller는 오픈 소스 프로젝트이며 Amazon에서 완전히 지원됩니다.

![Kubernetes Gateway API Objects and VPC Lattice Components](/docs/networking/vpc-lattice/fundamentals-mapping.webp)

그림에서 볼 수 있듯이 Kubernetes Gateway API의 다양한 제어 수준과 관련된 여러 페르소나가 있습니다:

- 인프라 제공자: Kubernetes `GatewayClass`를 생성하여 VPC Lattice를 GatewayClass로 식별합니다.
- 클러스터 운영자: Kubernetes `Gateway`를 생성하며, 이는 서비스 네트워크와 관련된 VPC Lattice의 정보를 가져옵니다.
- 애플리케이션 개발자: Gateway에서 백엔드 Kubernetes Service로 트래픽이 리디렉션되는 방법을 지정하는 `HTTPRoute` 객체를 생성합니다.

AWS Gateway API Controller는 Amazon VPC Lattice와 통합되며 다음을 수행할 수 있습니다:

- VPC 및 계정 간의 서비스 간 네트워크 연결을 원활하게 처리합니다.
- 여러 Kubernetes 클러스터에 걸쳐 있는 이러한 서비스를 검색합니다.
- 이러한 서비스 간의 통신을 보안하기 위해 심층 방어 전략을 구현합니다.
- 서비스 간 요청/응답 트래픽을 관찰합니다.

이 장에서는 `checkout` 마이크로서비스의 새 버전을 생성하고 Amazon VPC Lattice를 사용하여 A/B 테스트를 원활하게 수행합니다.

