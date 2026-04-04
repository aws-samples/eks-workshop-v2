---
title: "암호 화폐 런타임"
sidebar_position: 531
tmdTranslationSourceHash: '5a2c9673ac514386bbd593190b43b96d'
---

이 탐지 결과는 컨테이너가 Pod 내에서 암호 화폐 채굴을 시도했음을 나타냅니다.

탐지 결과를 시뮬레이션하기 위해 `default` 네임스페이스에서 `ubuntu` 이미지 Pod를 실행하고, 거기서 몇 가지 명령을 실행하여 암호 화폐 채굴 프로세스를 다운로드하는 것을 시뮬레이션합니다.

아래 명령을 실행하여 Pod를 시작합니다:

```bash
$ kubectl run crypto -n other --image ubuntu --restart=Never --command -- sleep infinity
$ kubectl wait --for=condition=ready pod crypto -n other
```

다음으로 `kubectl exec`를 사용하여 Pod 내에서 일련의 명령을 실행할 수 있습니다. 먼저 `curl` 유틸리티를 설치해 보겠습니다:

```bash
$ kubectl exec crypto -n other -- bash -c 'apt update && apt install -y curl'
```

다음으로 암호 화폐 채굴 프로세스를 다운로드하되 출력을 `/dev/null`로 보내겠습니다:

```bash test=false
$ kubectl exec crypto -n other -- bash -c 'curl -s -o /dev/null http://us-east.equihash-hub.miningpoolhub.com:12026 || true && echo "Done!"'
```

이러한 명령은 [GuardDuty 탐지 결과 콘솔](https://console.aws.amazon.com/guardduty/home#/findings)에서 세 가지 다른 탐지 결과를 트리거합니다.

첫 번째는 `Execution:Runtime/NewBinaryExecuted`로, APT 도구를 통해 설치된 `curl` 패키지와 관련이 있습니다.

![바이너리 실행 탐지 결과](/docs/security/guardduty/runtime-monitoring/binary-execution.webp)

이 탐지 결과의 세부 정보를 자세히 살펴보면, GuardDuty 런타임 모니터링과 관련되어 있기 때문에 런타임, 컨텍스트 및 프로세스에 관한 구체적인 정보를 표시합니다.

두 번째와 세 번째는 `CryptoCurrency:Runtime/BitcoinTool.B!DNS` 탐지 결과와 관련이 있습니다. 탐지 결과 세부 정보가 이번에는 `DNS_REQUEST` 작업과 **Threat intelligence Evidences**를 보여주는 다른 정보를 제공함을 주목하세요.

![암호 화폐 런타임 탐지 결과](/docs/security/guardduty/runtime-monitoring/crypto-runtime.webp)

