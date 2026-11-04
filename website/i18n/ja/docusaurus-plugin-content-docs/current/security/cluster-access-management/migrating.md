---
title: "aws-auth アイデンティティマッピングからの移行"
sidebar_position: 20
tmdTranslationSourceHash: "8ff42b2757efc1fb8f83998627dd75d7"
---

既に Amazon EKS を使用しているお客様は、クラスターへの IAM プリンシパルのアクセスを管理するための `aws-auth` ConfigMap の仕組みに慣れているかもしれません。ワークショップのクラスターは `API` 認証モードを使用しているため、アクセスエントリのみに依存しており、移行対象となる `aws-auth` ConfigMap は存在しません。

ご自身のクラスターを `aws-auth` ConfigMap からアクセスエントリに移行するには、Amazon EKS ユーザーガイドの [Migrating existing aws-auth ConfigMap entries to access entries](https://docs.aws.amazon.com/eks/latest/userguide/migrating-access-entries.html) に従ってください。`eksctl` でクラスターを管理している場合は、`eksctl` ドキュメントの [EKS access entries](https://docs.aws.amazon.com/eks/latest/eksctl/access-entries.html) も参照してください。

