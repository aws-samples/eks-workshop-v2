---
title: "Pod IAMの理解"
sidebar_position: 33
tmdTranslationSourceHash: '34ff18988cc9f932ada0b0e51dc7e163'
---

問題の最初の確認場所は、`carts`サービスのログです：

```bash hook=pod-logs timeout=480
$ LATEST_POD=$(kubectl get pods -n carts -l app.kubernetes.io/component=service --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
sleep 60
kubectl logs -n carts -p $LATEST_POD
[...]
software.amazon.awssdk.core.exception.SdkClientException: Unable to load credentials from any of the providers in the chain AwsCredentialsProviderChain(credentialsProviders=[SystemPropertyCredentialsProvider(), EnvironmentVariableCredentialsProvider(), WebIdentityTokenCredentialsProvider(), ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[])), ContainerCredentialsProvider(), InstanceProfileCredentialsProvider()]) : [SystemPropertyCredentialsProvider(): Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., EnvironmentVariableCredentialsProvider(): Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., WebIdentityTokenCredentialsProvider(): Either the environment variable AWS_WEB_IDENTITY_TOKEN_FILE or the javaproperty aws.webIdentityTokenFile must be set., ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[])): Profile file contained no credentials for profile 'default': ProfileFile(sections=[]), ContainerCredentialsProvider(): Cannot fetch credentials from container - neither AWS_CONTAINER_CREDENTIALS_FULL_URI or AWS_CONTAINER_CREDENTIALS_RELATIVE_URI environment variables are set., InstanceProfileCredentialsProvider(): Failed to load credentials from IMDS.]
```

アプリケーションはエラーを生成しており、PodがDynamoDBにアクセスするためのAWS認証情報を読み込めないことを示しています。これは、EKS Pod IdentityによってIAM roleやpolicyがPodにリンクされていない場合、アプリケーションがAWS API呼び出しを行うための認証情報を取得できないためです。

一つのアプローチとして、ノードのIAM roleの権限を拡張することが考えられますが、これではそれらのインスタンス上で実行されているすべてのPodがDynamoDBテーブルにアクセスできるようになってしまいます。これは最小権限の原則に違反し、セキュリティのベストプラクティスではありません。代わりに、EKS Pod Identityを使用して、`carts`アプリケーションが必要とする特定の権限をPodレベルで提供し、きめ細かいアクセス制御を確保します。

