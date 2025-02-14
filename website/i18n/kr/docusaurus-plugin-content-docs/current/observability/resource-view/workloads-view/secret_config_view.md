---
title: "ConfigMaps와 Secrets"
sidebar_position: 30
---

[ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)는 Key-Value 형식으로 구성 데이터를 저장하기 위한 쿠버네티스 리소스 객체입니다. ConfigMaps는 파드에 배포된 애플리케이션이 접근할 수 있는 환경 변수, 명령줄 인수, 애플리케이션 설정을 저장하는 데 유용합니다. ConfigMaps는 볼륨의 구성 파일로도 저장될 수 있습니다. 이를 통해 구성 데이터를 애플리케이션 코드와 분리할 수 있습니다.

ConfigMap 드릴다운을 클릭하면 클러스터의 모든 구성을 볼 수 있습니다.

![Insights](/img/resource-view/config-configMap.jpg)

ConfigMap <i>checkout</i>을 클릭하면 이와 관련된 속성들을 볼 수 있습니다. 이 경우에는 redis 엔드포인트 값을 가진 REDIS_URL 키가 있습니다. 보시다시피 값이 암호화되어 있지 않으므로 ConfigMaps는 기밀성이 있는 Key-Value 쌍을 저장하는 데 사용해서는 안 됩니다.

[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)는 사용자 이름, 비밀번호, 토큰 및 기타 자격 증명과 같은 민감한 데이터를 저장하기 위한 쿠버네티스 리소스 객체입니다. Secrets는 클러스터의 파드 전체에 민감한 정보를 구성하고 배포하는 데 도움이 됩니다. Secrets는 데이터 볼륨으로 마운트되거나 파드의 컨테이너에서 사용할 환경 변수로 노출되는 등 다양한 방식으로 사용될 수 있습니다.

Secrets 드릴다운을 클릭하면 클러스터의 모든 시크릿을 볼 수 있습니다.

![Insights](/img/resource-view/config-secrets.jpg)

Secrets <i>checkout-config</i>를 클릭하면 이와 관련된 시크릿을 볼 수 있습니다. 이 경우에는 인코딩된 <i>token</i>을 확인하세요. <i>decode</i> 토글 버튼을 사용하여 디코딩된 값도 볼 수 있습니다.