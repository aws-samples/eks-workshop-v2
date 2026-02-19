---
title: "Understanding Pod IAM"
sidebar_position: 33
---

The first place to look for the issue is the logs of the `carts` service:

```bash hook=pod-logs
$ LATEST_POD=$(kubectl get pods -n carts --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
$ kubectl logs -n carts -p $LATEST_POD
[...]
software.amazon.awssdk.core.exception.SdkClientException: Unable to load credentials from any of the providers in the chain AwsCredentialsProviderChain(credentialsProviders=[SystemPropertyCredentialsProvider(), EnvironmentVariableCredentialsProvider(), WebIdentityTokenCredentialsProvider(), ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[])), ContainerCredentialsProvider(), InstanceProfileCredentialsProvider()]) : [SystemPropertyCredentialsProvider(): Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., EnvironmentVariableCredentialsProvider(): Unable to load credentials from system settings. Access key must be specified either via environment variable (AWS_ACCESS_KEY_ID) or system property (aws.accessKeyId)., WebIdentityTokenCredentialsProvider(): Either the environment variable AWS_WEB_IDENTITY_TOKEN_FILE or the javaproperty aws.webIdentityTokenFile must be set., ProfileCredentialsProvider(profileName=default, profileFile=ProfileFile(sections=[])): Profile file contained no credentials for profile 'default': ProfileFile(sections=[]), ContainerCredentialsProvider(): Cannot fetch credentials from container - neither AWS_CONTAINER_CREDENTIALS_FULL_URI or AWS_CONTAINER_CREDENTIALS_RELATIVE_URI environment variables are set., InstanceProfileCredentialsProvider(): Failed to load credentials from IMDS.]
```

The application is generating an error which indicates that the Pod cannot load AWS credentials to access DynamoDB. This is happening because by default, when no IAM roles or policies are linked to our Pod via EKS Pod Identity, the application cannot obtain credentials to make AWS API calls.

One approach would be to expand the IAM permissions of the node IAM role, but this would allow any Pod running on those instances to access our DynamoDB table. This violates the principle of least privilege and is not a security best practice. Instead, we'll use EKS Pod Identity to provide the specific permissions required by the `carts` application at the Pod level, ensuring fine-grained access control.
