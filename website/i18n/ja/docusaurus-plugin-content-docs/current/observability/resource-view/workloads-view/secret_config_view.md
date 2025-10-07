---
title: "ConfigMaps と Secrets"
sidebar_position: 30
kiteTranslationSourceHash: b1254c86302c66178939b8a0b8f02af3
---

[ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) は、キーバリュー形式で設定データを保存するための Kubernetes リソースオブジェクトです。ConfigMapsは、Pod にデプロイされたアプリケーションがアクセスできる環境変数、コマンドライン引数、アプリケーション設定を保存するのに便利です。ConfigMapsはボリューム内の設定ファイルとして保存することもできます。これにより、設定データをアプリケーションコードから分離することができます。

ConfigMap のドリルダウンをクリックすると、クラスターのすべての設定を確認できます。

![Insights](/img/resource-view/config-configMap.jpg)

ConfigMap の <i>checkout</i> をクリックすると、それに関連付けられたプロパティが表示されます。この場合、キー REDIS_URL に redis エンドポイントの値が設定されています。ご覧のとおり、値は暗号化されておらず、ConfigMaps は機密性の高いキーと値のペアを保存するために使用すべきではありません。

[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) は、ユーザー名、パスワード、トークン、その他の認証情報などの機密データを保存するための Kubernetes リソースオブジェクトです。Secrets は、クラスター内の Pod 間で機密情報を整理して配布するのに役立ちます。Secrets はデータボリュームとしてマウントしたり、Pod内のコンテナが使用する環境変数として公開したりするなど、さまざまな方法で使用できます。

Secrets のドリルダウンをクリックすると、クラスターのすべての Secrets を確認できます。

![Insights](/img/resource-view/config-secrets.jpg)

Secrets の <i>checkout-config</i> をクリックすると、それに関連付けられた Secrets が表示されます。この場合、エンコードされた <i>token</i> に注目してください。<i>decode</i> トグルボタンを使用してデコードされた値も確認できます。

