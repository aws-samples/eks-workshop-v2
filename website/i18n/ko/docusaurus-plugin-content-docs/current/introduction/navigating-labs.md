---
title: 실습 탐색하기
sidebar_position: 25
tmdTranslationSourceHash: 3ef210656bc2a09d2ad75d89542ca72f
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

이 웹사이트와 제공되는 콘텐츠를 탐색하는 방법을 살펴보겠습니다.

## 구조

이 워크샵의 콘텐츠는 다음과 같이 구성되어 있습니다:

1. 개별 실습 과제
2. 실습과 관련된 개념을 설명하는 지원 콘텐츠

실습 과제는 독립적인 연습으로 모든 모듈을 실행할 수 있도록 설계되었습니다. 실습 과제는 왼쪽 사이드바에 표시되며 다음과 같은 아이콘으로 표시됩니다:

![Lab icon example](/docs/introduction/lab-icon.webp)

이 모듈에는 **Getting started**라는 단일 실습이 포함되어 있으며 화면 왼쪽에 표시됩니다.

:::caution
각 실습은 이 배지로 표시된 페이지에서 시작해야 합니다. 실습 중간부터 시작하면 예측할 수 없는 동작이 발생할 수 있습니다.
:::

브라우저에 따라 VSCode 터미널에 콘텐츠를 복사/붙여넣기할 때 처음으로 다음과 같은 프롬프트가 표시될 수 있습니다:

![VSCode copy/paste](/docs/introduction/vscode-copy-paste.webp)

## 터미널 명령어

이 워크샵에서 수행하는 대부분의 작업은 터미널 명령어를 통해 이루어지며, 수동으로 입력하거나 웹 IDE 터미널에 복사/붙여넣기할 수 있습니다. 터미널 명령어는 다음과 같이 표시됩니다:

```bash test=false
$ echo "This is an example command"
```

`echo "This is an example command"` 위로 마우스를 가져가서 클릭하면 해당 명령어가 클립보드에 복사됩니다.

또한 다음과 같이 샘플 출력이 포함된 명령어도 볼 수 있습니다:

```bash test=false
$ date
Fri Aug 30 12:25:58 MDT 2024
```

'클릭하여 복사' 기능을 사용하면 명령어만 복사되고 샘플 출력은 무시됩니다.

콘텐츠에서 사용되는 또 다른 패턴은 단일 터미널에 여러 명령어를 표시하는 것입니다:

```bash test=false
$ echo "This is an example command"
This is an example command
$ date
Fri Aug 30 12:26:58 MDT 2024
```

이 경우 각 명령어를 개별적으로 복사하거나 터미널 창 오른쪽 상단의 클립보드 아이콘을 사용하여 모든 명령어를 복사할 수 있습니다. 한번 시도해 보세요!

## EKS 클러스터 재설정

실수로 클러스터를 제대로 작동하지 않는 방식으로 구성한 경우, 언제든지 실행할 수 있는 EKS 클러스터 재설정 메커니즘이 제공됩니다. 간단히 `prepare-environment` 명령어를 실행하고 완료될 때까지 기다리면 됩니다. 실행 시 클러스터 상태에 따라 몇 분 정도 걸릴 수 있습니다.

## 다음 단계

이제 이 워크샵의 형식에 익숙해졌으니 [Getting started](/docs/introduction/getting-started) 실습으로 이동하거나 상단 네비게이션 바를 사용하여 워크샵의 모든 모듈로 바로 이동할 수 있습니다.

