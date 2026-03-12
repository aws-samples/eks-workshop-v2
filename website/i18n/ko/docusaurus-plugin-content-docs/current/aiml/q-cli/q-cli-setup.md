---
title: "설정"
sidebar_position: 20
tmdTranslationSourceHash: '8e17bb41e212ab90f60a7e3f8916cf3e'
---

이 섹션에서는 Amazon Q CLI와 [Amazon EKS용 MCP 서버](https://awslabs.github.io/mcp/servers/eks-mcp-server/)를 구성하여 자연어 명령으로 EKS 클러스터를 작업할 수 있도록 합니다.

:::info
Amazon Q CLI는 일반적인 개발 및 운영 작업을 위해 생성형 AI 기능을 활용합니다. 전문 지식을 위해 특별히 제작된 MCP 서버를 추가하여 기능을 향상시킬 수 있습니다. 이 섹션에서는 Amazon Q CLI와 함께 Amazon EKS MCP 서버를 사용할 것입니다. [여기](https://awslabs.github.io/mcp/)에서 AWS가 제공하는 MCP 서버 카탈로그를 찾을 수 있으며, 유사한 방식으로 Amazon Q CLI와 함께 사용할 수 있습니다.
:::

먼저, 운영 체제 및 CPU 아키텍처에 맞는 Amazon Q CLI 릴리스를 다운로드합니다:

```bash
$ ARCH=$(arch)
$ curl --proto '=https' --tlsv1.2 \
  -sSf https://desktop-release.q.us-east-1.amazonaws.com/1.12.4/q-${ARCH}-linux.zip \
  -o /tmp/q.zip
```

Amazon Q CLI를 설치합니다:

```bash
$ unzip /tmp/q.zip -d /tmp
$ sudo Q_INSTALL_GLOBAL=true /tmp/q/install.sh --no-confirm
```

설치를 확인합니다:

```bash
$ q --version
q 1.12.4
```

다음으로, Amazon EKS MCP 서버로 Amazon Q CLI를 구성하겠습니다. 다음은 사용할 구성입니다:

```file
manifests/modules/aiml/q-cli/setup/eks-mcp.json
```

MCP 서버를 구성하고 필요한 `uvx` 도구를 설치합니다:

:::info
`uvx`는 uv 패키지 관리자와 함께 제공되는 Python 패키지 실행 도구입니다. 전역으로 설치하지 않고 Python 패키지를 직접 실행합니다. 그런 다음 Node.js의 `npx`와 유사하지만 Python 패키지용인 격리된 환경에서 Python 도구를 다운로드하고 실행합니다.
:::

```bash
$ mkdir -p $HOME/.aws/amazonq
$ cp ~/environment/eks-workshop/modules/aiml/q-cli/setup/eks-mcp.json $HOME/.aws/amazonq/mcp.json
$ curl -LsSf https://astral.sh/uv/0.8.9/install.sh | sh
```

Amazon Q CLI를 사용하려면 AWS Builder ID 또는 Pro 라이선스 구독을 사용하여 인증해야 합니다.

:::tip
[이 지침](https://docs.aws.amazon.com/signin/latest/userguide/create-aws_builder_id.html)을 따라 무료 AWS Builder ID를 만들 수 있습니다. 이 Builder ID는 개인적으로 Amazon Q CLI를 사용하는 데에도 사용할 수 있습니다.
:::

```bash test=false
$ q login
? Select login method >
> Use for Free with Builder ID
  Use with Pro license
```

원하는 옵션을 선택하고 프롬프트에 따라 로그인 프로세스를 완료합니다. 로그인하거나 Amazon Q Developer가 계정을 사용하도록 권한을 부여하기 위해 웹 페이지로 리디렉션됩니다. 추가 안내는 다음을 참조하십시오:

- [AWS Builder ID로 로그인](https://docs.aws.amazon.com/signin/latest/userguide/sign-in-aws_builder_id.html)
- [Amazon Q Developer Pro 구독으로 로그인](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-admin-setup-subscribe-general.html)

세션을 초기화하여 MCP 서버가 사용 가능한지 확인해 보겠습니다:

```bash test=false
$ q
0 of 1 mcp servers initialized. Servers still loading:
 - awslabseks_mcp_server
```

EKS MCP 서버가 제공하는 도구를 보려면 다음을 실행합니다:

```text
/tools
```

다음과 유사한 출력이 표시됩니다:

![list-mcp-tools](/docs/aiml/q-cli/list-mcp-tools.jpg)

출력은 다음을 보여줍니다:

1. Amazon Q가 선택한 기본 대형 언어 모델(LLM) (`/model` 명령을 사용하여 변경 가능)
2. EKS MCP 서버가 제공하는 도구 목록
3. Amazon Q CLI가 각 도구에 대해 가지고 있는 기본 권한

:::info
도구가 `not trusted`로 표시되면 Amazon Q CLI가 사용하기 전에 권한을 요청합니다. 이것은 특히 리소스를 생성, 업데이트 또는 삭제할 수 있는 도구에 대한 안전 조치입니다. LLM이 실수를 할 수 있으므로, 이를 통해 잠재적으로 중단을 야기할 수 있는 작업이 실행되기 전에 검토할 기회를 제공합니다.
:::

동일한 절차를 따라 추가 기능을 위해 [AWS Labs의 다른 MCP 서버](https://awslabs.github.io/mcp/)를 추가할 수 있습니다. 이 실습에서는 구성한 EKS MCP 서버만 필요합니다.

다음 섹션에서는 Amazon Q CLI를 사용하여 EKS 클러스터에 대한 정보를 검색하겠습니다.

