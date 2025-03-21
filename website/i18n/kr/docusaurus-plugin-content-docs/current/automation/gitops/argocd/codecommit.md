---
title: "AWS CodeCommit 접근하기"
sidebar_position: 5
---

AWS CodeCommit 저장소가 우리의 실습 환경에 생성되었지만, IDE가 연결되기 전에 몇 가지 단계를 완료해야 합니다.

나중에 경고를 방지하기 위해 CodeCommit용 SSH 키를 known hosts 파일에 추가할 수 있습니다:

```bash
$ ssh-keyscan -H git-codecommit.${AWS_REGION}.amazonaws.com &> ~/.ssh/known_hosts
```

그리고 Git이 우리의 커밋에 사용할 신원을 설정할 수 있습니다:

```bash
$ git config --global user.email "you@eksworkshop.com"
$ git config --global user.name "Your Name"
```