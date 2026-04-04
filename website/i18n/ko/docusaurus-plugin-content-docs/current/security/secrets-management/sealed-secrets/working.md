---
title: "Kubernetes를 위한 Sealed Secrets"
sidebar_position: 431
tmdTranslationSourceHash: 'c9aa36b3e9d4014b051bd5e6b2d0f753'
---

Sealed Secrets는 두 부분으로 구성됩니다:

- 클러스터 측 controller
- `kubeseal`이라는 클라이언트 측 CLI

controller가 시작되면 클러스터 전체의 개인/공개 키 쌍을 찾고, 찾지 못하면 새로운 4096비트 RSA 키 쌍을 생성합니다. 개인 키는 controller와 동일한 네임스페이스(기본적으로 kube-system)의 Secret 객체에 저장됩니다. 이 키의 공개 키 부분은 이 클러스터에서 SealedSecrets를 사용하려는 모든 사용자가 공개적으로 사용할 수 있습니다.

암호화 과정에서 원본 Secret의 각 값은 무작위로 생성된 세션 키를 사용하여 AES-256으로 대칭 암호화됩니다. 그런 다음 세션 키는 원본 Secret의 네임스페이스/이름을 입력 매개변수로 사용하여 SHA256과 controller의 공개 키로 비대칭 암호화됩니다. 암호화 프로세스의 출력은 다음과 같이 구성된 문자열입니다:
암호화된 세션 키의 길이(2바이트) + 암호화된 세션 키 + 암호화된 Secret

SealedSecret 커스텀 리소스가 Kubernetes 클러스터에 배포되면 controller가 이를 감지하고 개인 키를 사용하여 봉인을 해제하고 Secret 리소스를 생성합니다. 복호화 과정에서 SealedSecret의 네임스페이스/이름이 다시 입력 매개변수로 사용됩니다. 이는 SealedSecret과 Secret이 동일한 네임스페이스와 이름에 엄격하게 연결되도록 보장합니다.

함께 제공되는 CLI 도구인 kubeseal은 공개 키를 사용하여 Secret 리소스 정의에서 SealedSecret 커스텀 리소스 정의(CRD)를 생성하는 데 사용됩니다. kubeseal은 Kubernetes API 서버를 통해 controller와 통신하고 런타임에 Secret을 암호화하는 데 필요한 공개 키를 검색할 수 있습니다. 공개 키는 controller에서 다운로드하여 로컬에 저장하여 오프라인으로 사용할 수도 있습니다.

SealedSecrets는 다음 세 가지 범위를 가질 수 있습니다:

- **strict (기본값)**: Secret은 정확히 동일한 이름과 네임스페이스로 봉인되어야 합니다. 이러한 속성은 암호화된 데이터의 일부가 되므로 이름 및/또는 네임스페이스를 변경하면 "복호화 오류"가 발생합니다.
- **namespace-wide**: 봉인된 Secret은 주어진 네임스페이스 내에서 자유롭게 이름을 변경할 수 있습니다.
- **cluster-wide**: Secret은 모든 네임스페이스에서 봉인을 해제할 수 있으며 모든 이름을 지정할 수 있습니다.

