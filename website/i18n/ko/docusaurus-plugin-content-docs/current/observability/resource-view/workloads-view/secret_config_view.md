---
title: "ConfigMap과 Secret"
sidebar_position: 30
tmdTranslationSourceHash: 'b1254c86302c66178939b8a0b8f02af3'
---

[ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)은 키-값 형식으로 구성 데이터를 저장하는 Kubernetes 리소스 객체입니다. ConfigMap은 환경 변수, 명령줄 인수, Pod에 배포된 애플리케이션에서 액세스할 수 있는 애플리케이션 구성을 저장하는 데 유용합니다. ConfigMap은 볼륨의 구성 파일로도 저장할 수 있습니다. 이는 구성 데이터를 애플리케이션 코드와 분리하는 데 도움이 됩니다.

ConfigMap 드릴다운을 클릭하면 클러스터의 모든 구성을 볼 수 있습니다.

![Insights](/img/resource-view/config-configMap.jpg)

ConfigMap <i>checkout</i>을 클릭하면 여기에 연결된 속성을 볼 수 있습니다. 이 경우 redis 엔드포인트 값을 가진 키 REDIS_URL입니다. 보시다시피 값이 암호화되지 않았으며 ConfigMap은 기밀 키-값 쌍을 저장하는 데 사용해서는 안 됩니다.

[Secret](https://kubernetes.io/docs/concepts/configuration/secret/)은 사용자 이름, 비밀번호, 토큰 및 기타 자격 증명과 같은 민감한 데이터 조각을 저장하기 위한 Kubernetes 리소스 객체입니다. Secret은 클러스터의 Pod 전체에서 민감한 정보를 구성하고 배포하는 데 유용합니다. Secret은 데이터 볼륨으로 마운트되거나 Pod의 컨테이너에서 사용할 환경 변수로 노출되는 등 다양한 방식으로 사용할 수 있습니다.

Secret 드릴다운을 클릭하면 클러스터의 모든 시크릿을 볼 수 있습니다.

![Insights](/img/resource-view/config-secrets.jpg)

Secret <i>checkout-config</i>를 클릭하면 여기에 연결된 시크릿을 볼 수 있습니다. 이 경우 인코딩된 <i>token</i>을 확인할 수 있습니다. <i>decode</i> 토글 버튼을 사용하여 디코딩된 값도 확인할 수 있습니다.

