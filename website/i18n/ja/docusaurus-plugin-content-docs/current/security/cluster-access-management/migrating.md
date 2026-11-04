---
title: "aws-auth アイデンティティマッピングからの移行"
sidebar_position: 20
tmdTranslationSourceHash: "8ff42b2757efc1fb8f83998627dd75d7"
---

Amazon EKS を既に使用しているお客様は、クラスターへの IAM プリンシパルアクセスを管理するための `aws-auth` ConfigMap メカニズムに慣れているかもしれません。ワークショップのクラスターは `API` 認証モードを使用しているため、アクセスエントリのみに依存しており、移行対象となる `aws-auth` ConfigMap はありません。

ご自身のクラスターを `aws-auth` ConfigMap からアクセスエントリに移行するには、Amazon EKS ユーザーガイドの [既存の aws-auth ConfigMap エントリをアクセスエントリに移行する](https://docs.aws.amazon.com/eks/latest/userguide/migrating-access-entries.html) に従ってください。`eksctl` でクラスターを管理している場合は、`eksctl` ドキュメントの [EKS アクセスエントリ](https://docs.aws.amazon.com/eks/latest/eksctl/access-entries.html) も参照してください。
