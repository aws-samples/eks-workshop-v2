---
title: "Pod IAM の理解"
sidebar_position: 33
tmdTranslationSourceHash: '34ff18988cc9f932ada0b0e51dc7e163'
---

問題の最初の調査先は `carts` サービスのログです：

```bash hook=pod-logs timeout=480
$ LATEST_POD=$(kubectl get pods -n carts -l app.kubernetes.io/component=service --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
sleep 60
kubectl logs -n carts -p $LATEST_POD
[...]
software.amazon.awssdk.core.exception.SdkClientException: Unable to load credentials from any of the providers in the chain AwsCredentialsProviderChain(credentialsProviders=[SystemPropertyCredentialsProvider(), EnvironmentVariableCredentialsProvider(), WebIdentityTokenCredentialsProvider(), ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[])), ContainerCredentialsProvider(), InstanceProfileCredentialsProvider()]) : [SystemPropertyCredentialsProvider(): Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., EnvironmentVariableCredentialsProvider(): Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., WebIdentityTokenCredentialsProvider(): Either the environment variable AWS_WEB_IDENTITY_TOKEN_FILE or the javaproperty aws.webIdentityTokenFile must be set., ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[])): Profile file contained no credentials for profile 'default': ProfileFile(sections=[]), ContainerCredentialsProvider(): Cannot fetch credentials from container - neither AWS_CONTAINER_CREDENTIALS_FULL_URI or AWS_CONTAINER_CREDENTIALS_RELATIVE_URI environment variables are set., InstanceProfileCredentialsProvider(): Failed to load credentials from IMDS.]
```

アプリケーションがエラーを生成しており、Pod が DynamoDB にアクセスするための AWS 認証情報を読み込めないことを示しています。これは、EKS Pod Identity を介して IAM ロールやポリシーが Pod にリンクされていない場合、デフォルトでアプリケーションが AWS API 呼び出しを行うための認証情報を取得できないために発生しています。

1つのアプローチは、ノード IAM ロールの IAM 権限を拡張することですが、これではそれらのインスタンスで実行されている任意の Pod が DynamoDB テーブルにアクセスできるようになってしまいます。これは最小権限の原則に違反し、セキュリティのベストプラクティスではありません。代わりに、EKS Pod Identity を使用して、`carts` アプリケーションが必要とする特定の権限を Pod レベルで提供し、きめ細かいアクセス制御を確保します。

